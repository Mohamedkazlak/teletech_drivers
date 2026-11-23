import { fireEvent, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { ReactElement } from 'react'
import { api } from '../../api/client'
import type { TripSummary, User } from '../../api/types'
import { AuthContext } from '../../auth/auth-context'
import i18n from '../../i18n'
import { cairoInputToIso } from '../../lib/cairo-schedule'
import { paginated, place, renderPage, tripSummary } from '../../test/render-page'
import { MyTripsPage } from './MyTripsPage'

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

const places = [
  place({ id: 'place-1', name_en: 'Headquarters', name_ar: 'المقر' }),
  place({ id: 'place-2', name_en: 'Site', name_ar: 'الموقع', is_headquarters: false }),
]

function myTripQueries() {
  return http.get.mock.calls
    .filter((call) => call[0] === '/my-trips')
    .map((call) => (call[1] as { query?: Record<string, unknown> }).query)
}

describe('drivers admin my trips', () => {
  beforeEach(async () => {
    http.get.mockReset()
    http.post.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockImplementation(async (path: string) => {
      if (path === '/my-trips') return paginated([])
      if (path === '/places') return paginated(places)
      if (path.endsWith('/driver-recommendations')) return { data: [] }
      throw new Error(path)
    })
  })

  it('sends the bucket tabs', async () => {
    const user = userEvent.setup()
    renderPage(<MyTripsPage />)

    await waitFor(() => {
      expect(myTripQueries()).toContainEqual({ bucket: 'all', per_page: 15 })
    })

    await user.selectOptions(screen.getByRole('combobox', { name: 'My trips' }), 'Completed')
    await waitFor(() => {
      expect(myTripQueries()).toContainEqual({ bucket: 'completed', per_page: 15 })
    })

    await user.selectOptions(screen.getByRole('combobox', { name: 'My trips' }), 'Cancelled')
    await waitFor(() => {
      expect(myTripQueries()).toContainEqual({ bucket: 'cancelled', per_page: 15 })
    })
  })

  it('creates an unassigned trip without an extra assignment step', async () => {
    const user = userEvent.setup()
    http.post.mockImplementation(async (path: string) => {
      if (path === '/trip-requests') {
        return { id: 'req-9', status: 'approved', auto_approved: true, trip_id: 'trip-9' }
      }
      throw new Error(path)
    })

    renderPage(<MyTripsPage />)
    await user.click(screen.getByRole('button', { name: 'Request a trip' }))
    const dialog = await screen.findByRole('dialog', { name: 'Request a trip' })
    await waitFor(() => expect(within(dialog).getByLabelText('From')).toBeEnabled())
    await user.selectOptions(within(dialog).getByLabelText('From'), 'place-1')
    await user.selectOptions(within(dialog).getByLabelText('To'), 'place-2')
    fireEvent.change(within(dialog).getByLabelText('When'), {
      target: { value: '2027-06-01T09:30' },
    })
    await user.type(within(dialog).getByLabelText('Passenger notes'), 'Window seat')
    await user.click(within(dialog).getByRole('button', { name: 'Submit request' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/trip-requests', {
        pickup: { place_id: 'place-1' },
        destination: { place_id: 'place-2' },
        requested_at: cairoInputToIso('2027-06-01T09:30'),
        notes: 'Window seat',
      })
    })
    expect(http.post).not.toHaveBeenCalledWith(
      '/trips/from-requests',
      expect.anything(),
    )
    expect(screen.queryByRole('dialog', { name: 'Assign a driver' })).not.toBeInTheDocument()
    expect(
      await screen.findByText('Your trip is unassigned. Open it here to choose a driver.'),
    ).toBeInTheDocument()
    expect(
      screen.queryByText('Your request was accepted and sent to the drivers admin.'),
    ).not.toBeInTheDocument()
  })

  it('lets the drivers admin confirm their own finished trip', async () => {
    const user = userEvent.setup()
    let confirmed = false
    const trip = (done: boolean): TripSummary =>
      tripSummary({
        id: 'trip-1',
        status: 'completed',
        confirmation_status: done ? 'confirmed' : 'pending',
        driver_showed_up: done ? true : null,
        passengers: [
          {
            employee_id: 'user-1',
            name_en: 'Nader',
            name_ar: null,
            phone: null,
            branch: 'company_headquarters',
            request_id: 'req-9',
            pickup: { place_id: 'place-1', name: 'HQ', lat: 1, lng: 2, address: null },
            destination: { place_id: 'place-2', name: 'Site', lat: 3, lng: 4, address: null },
          },
        ],
      })
    http.get.mockImplementation(async (path: string) => {
      if (path === '/my-trips') return paginated([trip(confirmed)])
      if (path === '/trips/trip-1') return trip(confirmed)
      if (path === '/trips/trip-1/report') {
        return {
          status: 'completed',
          is_in_progress: false,
          start: null,
          finish: null,
          going_duration_seconds: null,
          waiting_duration_seconds: null,
          return_duration_seconds: null,
          total_duration_seconds: null,
          going_distance_km: null,
          return_distance_km: null,
          total_distance_km: null,
          going_route: null,
          return_route: null,
          driven_route: [],
        }
      }
      if (path.endsWith('/driver-recommendations')) return { data: [] }
      throw new Error(path)
    })
    http.post.mockImplementation(async (path: string) => {
      if (path === '/trip-requests/req-9/confirm-trip') {
        confirmed = true
        return { id: 'req-9' }
      }
      throw new Error(path)
    })

    renderAs(<MyTripsPage />)
    await user.click(await screen.findByRole('button', { name: 'View' }))
    const dialog = await screen.findByRole('dialog', { name: 'Trip details' })
    const listedBefore = http.get.mock.calls.filter((call) => call[0] === '/my-trips').length
    const detailBefore = http.get.mock.calls.filter((call) => call[0] === '/trips/trip-1').length

    await user.click(within(dialog).getByRole('button', { name: 'Driver showed up' }))
    await user.click(within(dialog).getByRole('button', { name: 'Submit report' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/trip-requests/req-9/confirm-trip', {
        driver_showed_up: true,
      })
    })
    await waitFor(() => {
      expect(http.get.mock.calls.filter((call) => call[0] === '/my-trips').length).toBeGreaterThan(
        listedBefore,
      )
      expect(
        http.get.mock.calls.filter((call) => call[0] === '/trips/trip-1').length,
      ).toBeGreaterThan(detailBefore)
    })
    await waitFor(() => {
      expect(within(dialog).queryByRole('button', { name: 'Submit report' })).not.toBeInTheDocument()
    })
  })
})

function renderAs(ui: ReactElement) {
  const person: User = {
    id: 'user-1',
    name_en: 'Nader',
    name_ar: null,
    email: 'nader@example.com',
    role: 'drivers_admin',
    is_active: true,
    phone: null,
    branch: null,
    must_change_password: false,
    is_available: false,
  }
  return renderPage(
    <AuthContext.Provider
      value={{
        status: 'authenticated',
        user: person,
        login: vi.fn(),
        logout: vi.fn(),
        refresh: vi.fn(async () => person),
      }}
    >
      {ui}
    </AuthContext.Provider>,
  )
}
