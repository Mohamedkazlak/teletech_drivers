import { fireEvent, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import { ApiError } from '../../api/errors'
import type { DriverRecommendation, DriverSummary } from '../../api/types'
import i18n from '../../i18n'
import { cairoInputToIso } from '../../lib/cairo-schedule'
import {
  paginated,
  renderPage,
  tripRequest,
  tripSummary,
  chooseRowAction,
} from '../../test/render-page'
import { RequestsPage } from './RequestsPage'

vi.mock('../../components/map/MapView', () => ({
  MapView: () => null,
}))

vi.mock('../../api/client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const http = vi.mocked(api)

function listQueries() {
  return http.get.mock.calls
    .filter((call) => call[0] === '/trip-requests')
    .map((call) => (call[1] as { query?: Record<string, unknown> }).query)
}

function recommendation(
  name: string,
  overrides: Partial<Omit<DriverRecommendation, 'driver'>> = {},
): DriverRecommendation {
  const unavailable = overrides.is_unavailable === true
  const driver: DriverSummary = {
    id: name,
    name_en: name,
    name_ar: null,
    email: `${name}@example.com`,
    role: 'driver',
    is_active: true,
    phone: null,
    is_available: !unavailable,
    favorite_place_ids: [],
    deleted_at: null,
    deleted_by: null,
  }
  return {
    tier: 1,
    has_favorite_match: false,
    has_conflict: false,
    is_on_active_trip: false,
    is_unavailable: false,
    needs_confirmation: false,
    trips_this_week: 1,
    ...overrides,
    driver,
  }
}

describe('drivers admin requests', () => {
  beforeEach(async () => {
    http.get.mockReset()
    http.post.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trip-requests/grouping-suggestions') return { data: [] }
      if (path === '/trip-requests') return paginated([tripRequest({ status: 'approved' })])
      throw new Error(path)
    })
  })

  it('sends the pending and approved tabs and the branch filter', async () => {
    const user = userEvent.setup()
    renderPage(<RequestsPage />)

    expect(await screen.findByText('Sara Nabil')).toBeInTheDocument()
    await waitFor(() => {
      expect(listQueries()).toContainEqual({ has_trip: false, per_page: 15 })
    })

    await user.selectOptions(screen.getByRole('combobox', { name: 'Status' }), 'Approved')
    await waitFor(() => {
      expect(listQueries()).toContainEqual({ has_trip: true, per_page: 15 })
    })

    await user.selectOptions(screen.getByRole('combobox', { name: 'Branch' }), 'New Headquarters')
    await waitFor(() => {
      expect(listQueries()).toContainEqual({
        has_trip: true,
        branch: 'new_headquarters',
        per_page: 15,
      })
    })
  })

  it('creates one trip and shows recommended drivers before a disabled driver', async () => {
    const user = userEvent.setup()
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trip-requests/grouping-suggestions') return { data: [] }
      if (path === '/trip-requests') return paginated([tripRequest({ status: 'approved' })])
      if (path.endsWith('/driver-recommendations')) {
        return {
          data: [
            recommendation('Ziad', {
              tier: 2,
              is_unavailable: true,
              needs_confirmation: true,
              trips_this_week: 0,
            }),
            recommendation('Mona', {
              tier: 0,
              has_favorite_match: true,
              trips_this_week: 2,
            }),
          ],
        }
      }
      throw new Error(path)
    })
    http.post.mockImplementation(async (path: string) => {
      if (path === '/trips/from-requests') return { data: [tripSummary({ id: 'trip-new' })] }
      throw new ApiError(
        'Driver can only be assigned when the trip is unassigned or assigned.',
        409,
      )
    })

    renderPage(<RequestsPage />)
    await chooseRowAction(user, 'Sara Nabil', 'Create trip & assign driver')

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/trips/from-requests', {
        mode: 'one_per_request',
        request_ids: ['req-1'],
      })
    })

    const dialog = await screen.findByRole('dialog', { name: 'Assign a driver' })
    const radios = within(dialog).getAllByRole('radio')
    expect(radios[0]).toHaveAccessibleName(/Mona/)
    expect(radios[1]).toBeDisabled()
    expect(within(dialog).getByText('Favorite place')).toBeInTheDocument()
    expect(within(dialog).getByText('2 trips this week')).toBeInTheDocument()

    await user.click(radios[0]!)
    await user.click(within(dialog).getByRole('button', { name: 'Assign driver' }))

    expect(
      await within(dialog).findByText(
        'Driver can only be assigned when the trip is unassigned or assigned.',
      ),
    ).toBeInTheDocument()
    expect(http.post).toHaveBeenCalledWith('/trips/trip-new/assign', { driver_id: 'Mona' })
  })

  it('creates one grouped trip from several selected requests', async () => {
    const user = userEvent.setup()
    const first = tripRequest({ id: 'req-1', status: 'approved', employee_name_en: 'Sara Nabil' })
    const second = tripRequest({
      id: 'req-2',
      status: 'approved',
      employee_name_en: 'Omar Fathy',
    })
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trip-requests/grouping-suggestions') return { data: [] }
      if (path === '/trip-requests') return paginated([first, second])
      if (path.endsWith('/driver-recommendations')) return { data: [] }
      throw new Error(path)
    })
    http.post.mockResolvedValue({ data: [tripSummary({ id: 'trip-group' })] })

    renderPage(<RequestsPage />)
    await user.click(await screen.findByRole('checkbox', { name: 'Select Sara Nabil' }))
    await user.click(screen.getByRole('checkbox', { name: 'Select Omar Fathy' }))
    const selection = screen.getByRole('region', { name: 'Selected requests' })
    await user.click(within(selection).getByRole('button', { name: 'Create trip & assign driver' }))

    const schedule = await screen.findByRole('dialog', { name: 'When should this trip run?' })
    fireEvent.change(within(schedule).getByLabelText('When'), {
      target: { value: '2027-06-01T09:30' },
    })
    await user.click(within(schedule).getByRole('button', { name: 'Create trip & assign driver' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/trips/from-requests', {
        mode: 'grouped',
        request_ids: ['req-1', 'req-2'],
        scheduled_at: cairoInputToIso('2027-06-01T09:30'),
      })
    })
    expect(await screen.findByRole('dialog', { name: 'Assign a driver' })).toBeInTheDocument()
  })

  it('renders Arabic from right to left', async () => {
    await i18n.changeLanguage('ar')
    renderPage(<RequestsPage />)

    expect(document.documentElement.dir).toBe('rtl')
    expect(await screen.findByRole('heading', { name: 'الطلبات' })).toBeInTheDocument()
    expect(await screen.findByText('سارة نبيل')).toBeInTheDocument()
  })
})
