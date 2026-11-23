import { fireEvent, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { ReactElement } from 'react'
import { api } from '../../api/client'
import { ApiError } from '../../api/errors'
import type { TripSummary, User } from '../../api/types'
import { AuthContext } from '../../auth/auth-context'
import i18n from '../../i18n'
import { paginated, place, renderPage, tripSummary } from '../../test/render-page'
import { cairoInputToIso, isFutureCairoInput } from '../../lib/cairo-schedule'
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

function myTripQueries() {
  return http.get.mock.calls
    .filter((call) => call[0] === '/my-trips')
    .map((call) => (call[1] as { query?: Record<string, unknown> }).query)
}

const places = [
  place({ id: 'place-1', name_en: 'Headquarters', name_ar: 'المقر' }),
  place({
    id: 'place-2',
    name_en: 'Site',
    name_ar: 'الموقع',
    is_headquarters: false,
  }),
]

describe('my trips request form', () => {
  it('sends the bucket and does not filter the rows again', async () => {
    const user = userEvent.setup()
    http.get.mockImplementation(async (path: string, options?: { query?: { bucket?: string } }) => {
      if (path !== '/my-trips') throw new Error(path)
      if (options?.query?.bucket === 'active') {
        return paginated([
          tripSummary({
            id: 'trip-kept',
            status: 'completed',
            pickup_summary: 'Kept',
            destination_summary: 'Plant',
          }),
        ])
      }
      return paginated([])
    })

    renderPage(<MyTripsPage />)

    await waitFor(() => {
      expect(myTripQueries()).toContainEqual({ bucket: 'all', per_page: 15 })
    })

    await user.selectOptions(screen.getByRole('combobox', { name: 'My trips' }), 'Active')

    expect(await screen.findByText('Kept to Plant')).toBeInTheDocument()
    expect(myTripQueries()).toContainEqual({ bucket: 'active', per_page: 15 })
  })

  beforeEach(async () => {
    http.get.mockReset()
    http.post.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockImplementation(async (path: string) => {
      if (path === '/my-trips') return paginated([])
      if (path === '/places') return paginated(places)
      throw new Error(path)
    })
  })

  it('requires a route and a future time before submit', async () => {
    const user = userEvent.setup()
    renderPage(<MyTripsPage />)
    await user.click(screen.getByRole('button', { name: 'Request a trip' }))
    const dialog = await screen.findByRole('dialog', { name: 'Request a trip' })
    await user.click(within(dialog).getByRole('button', { name: 'Submit request' }))

    expect(await within(dialog).findAllByText('This field is required.')).toHaveLength(3)
    expect(http.post).not.toHaveBeenCalled()
  })

  it('submits the request and shows the accepted status', async () => {
    const user = userEvent.setup()
    http.post.mockResolvedValue({
      id: 'req-9',
      status: 'approved',
      auto_approved: true,
      employee_name_en: 'Mona',
      employee_name_ar: null,
      employee_phone: null,
      employee_branch: 'company_headquarters',
      employee_id: 'user-1',
      requester_role: 'company_admin',
      pickup: { place_id: 'place-1', name: 'Headquarters', lat: 1, lng: 2, address: null },
      destination: { place_id: 'place-2', name: 'Site', lat: 3, lng: 4, address: null },
      requested_at: '2027-06-01T07:30:00.000Z',
      notes: 'Window seat',
      trip_id: null,
      trip_status: null,
      rejection_reason: null,
      handled_by: null,
      handled_at: null,
      suggested_group_id: null,
      created_at: '2026-11-10T08:00:00.000Z',
      trip: null,
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
    expect(await within(dialog).findByText('Approved')).toBeInTheDocument()
    expect(
      within(dialog).getByText('Your request was accepted and sent to the drivers admin.'),
    ).toBeInTheDocument()
  })

  it('defaults an empty time field to the next Cairo slot', async () => {
    vi.useFakeTimers({ toFake: ['Date'] })
    vi.setSystemTime(new Date('2026-11-16T12:00:00.000Z'))
    const user = userEvent.setup()
    renderPage(<MyTripsPage />)
    await user.click(screen.getByRole('button', { name: 'Request a trip' }))
    const dialog = await screen.findByRole('dialog', { name: 'Request a trip' })
    const when = within(dialog).getByLabelText('When')
    expect(when).toHaveValue('')
    await user.click(when)
    expect(when).toHaveValue('2026-11-16T14:01')
    expect(when).toHaveAttribute('min', '2026-11-16T14:01')
    vi.useRealTimers()
  })

  it('rejects a past time before calling the API', async () => {
    const user = userEvent.setup()
    renderPage(<MyTripsPage />)
    await user.click(screen.getByRole('button', { name: 'Request a trip' }))
    const dialog = await screen.findByRole('dialog', { name: 'Request a trip' })
    await waitFor(() => expect(within(dialog).getByLabelText('From')).toBeEnabled())
    await user.selectOptions(within(dialog).getByLabelText('From'), 'place-1')
    await user.selectOptions(within(dialog).getByLabelText('To'), 'place-2')
    fireEvent.change(within(dialog).getByLabelText('When'), {
      target: { value: '2020-01-01T09:00' },
    })
    await user.click(within(dialog).getByRole('button', { name: 'Submit request' }))

    expect(await within(dialog).findByText('Choose a time in the future.')).toBeInTheDocument()
    expect(isFutureCairoInput('2020-01-01T09:00')).toBe(false)
    expect(http.post).not.toHaveBeenCalled()
  })

  it('shows a 422 schedule message on the time field', async () => {
    const user = userEvent.setup()
    http.post.mockRejectedValue(
      new ApiError('The given data was invalid.', 422, {
        errors: {
          requested_at: ['The scheduled time must be in the future.'],
          scheduled_at: ['The scheduled time must be in the future.'],
        },
      }),
    )

    renderPage(<MyTripsPage />)
    await user.click(screen.getByRole('button', { name: 'Request a trip' }))
    const dialog = await screen.findByRole('dialog', { name: 'Request a trip' })
    await waitFor(() => expect(within(dialog).getByLabelText('From')).toBeEnabled())
    await user.selectOptions(within(dialog).getByLabelText('From'), 'place-1')
    await user.selectOptions(within(dialog).getByLabelText('To'), 'place-2')
    fireEvent.change(within(dialog).getByLabelText('When'), {
      target: { value: '2027-06-01T09:30' },
    })
    await user.click(within(dialog).getByRole('button', { name: 'Submit request' }))

    expect(
      await within(dialog).findByText('The scheduled time must be in the future.'),
    ).toBeInTheDocument()
  })

  it('shows a 422 field error from the API', async () => {
    const user = userEvent.setup()
    http.post.mockRejectedValue(
      new ApiError('The given data was invalid.', 422, {
        errors: { destination: ['Pickup and destination must be different.'] },
      }),
    )

    renderPage(<MyTripsPage />)
    await user.click(screen.getByRole('button', { name: 'Request a trip' }))
    const dialog = await screen.findByRole('dialog', { name: 'Request a trip' })
    await waitFor(() => expect(within(dialog).getByLabelText('From')).toBeEnabled())
    await user.selectOptions(within(dialog).getByLabelText('From'), 'place-1')
    await user.selectOptions(within(dialog).getByLabelText('To'), 'place-2')
    fireEvent.change(within(dialog).getByLabelText('When'), {
      target: { value: '2027-06-01T09:30' },
    })
    await user.click(within(dialog).getByRole('button', { name: 'Submit request' }))

    expect(
      await within(dialog).findByText('Pickup and destination must be different.'),
    ).toBeInTheDocument()
  })

  it('lets the requester confirm a finished trip and marks it completed', async () => {
    const user = userEvent.setup()
    let confirmed = false
    const trip = (done: boolean): TripSummary =>
      tripSummary({
        id: 'trip-1',
        status: 'completed',
        confirmation_status: done ? 'confirmed' : 'pending',
        driver_showed_up: done ? false : null,
        passengers: [
          {
            employee_id: 'user-1',
            name_en: 'Mona',
            name_ar: null,
            phone: null,
            branch: 'company_headquarters',
            request_id: 'req-1',
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
      if (path === '/places') return paginated(places)
      throw new Error(path)
    })
    http.post.mockImplementation(async (path: string, body?: unknown) => {
      if (path === '/trip-requests/req-1/confirm-trip') {
        confirmed = true
        return { id: 'req-1', body }
      }
      throw new Error(path)
    })

    renderAs(<MyTripsPage />, 'company_admin')
    await user.click(await screen.findByRole('button', { name: 'View' }))
    const dialog = await screen.findByRole('dialog', { name: 'Trip details' })
    expect(within(dialog).getByText('Awaiting report')).toBeInTheDocument()
    expect(within(dialog).queryByRole('button', { name: 'Submit report' })).toBeInTheDocument()

    const myTripsBefore = http.get.mock.calls.filter((call) => call[0] === '/my-trips').length
    const tripsBefore = http.get.mock.calls.filter((call) => call[0] === '/trips/trip-1').length
    await user.click(within(dialog).getByRole('button', { name: 'Did not show up' }))
    await user.type(within(dialog).getByLabelText('Optional note'), 'Late')
    await user.click(within(dialog).getByRole('button', { name: 'Submit report' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/trip-requests/req-1/confirm-trip', {
        driver_showed_up: false,
        note: 'Late',
      })
    })
    await waitFor(() => {
      expect(http.get.mock.calls.filter((call) => call[0] === '/my-trips').length).toBeGreaterThan(
        myTripsBefore,
      )
      expect(
        http.get.mock.calls.filter((call) => call[0] === '/trips/trip-1').length,
      ).toBeGreaterThan(tripsBefore)
    })
    await waitFor(() => {
      expect(within(dialog).queryByRole('button', { name: 'Submit report' })).not.toBeInTheDocument()
    })
    expect(screen.queryByText('Awaiting report')).not.toBeInTheDocument()
  })

  it('keeps someone else’s finished trip read-only', async () => {
    const user = userEvent.setup()
    http.get.mockImplementation(async (path: string) => {
      if (path === '/my-trips') {
        return paginated([
          tripSummary({
            id: 'trip-2',
            status: 'completed',
            confirmation_status: 'pending',
            passengers: [
              {
                employee_id: 'someone-else',
                name_en: 'Other',
                name_ar: null,
                phone: null,
                branch: null,
                request_id: 'req-2',
                pickup: { place_id: null, name: 'HQ', lat: null, lng: null, address: null },
                destination: { place_id: null, name: 'Site', lat: null, lng: null, address: null },
              },
            ],
          }),
        ])
      }
      if (path === '/trips/trip-2') {
        return tripSummary({
          id: 'trip-2',
          status: 'completed',
          confirmation_status: 'pending',
          passengers: [
            {
              employee_id: 'someone-else',
              name_en: 'Other',
              name_ar: null,
              phone: null,
              branch: null,
              request_id: 'req-2',
              pickup: { place_id: null, name: 'HQ', lat: null, lng: null, address: null },
              destination: { place_id: null, name: 'Site', lat: null, lng: null, address: null },
            },
          ],
        })
      }
      if (path === '/trips/trip-2/report') {
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
      throw new Error(path)
    })

    renderAs(<MyTripsPage />, 'company_admin')
    await user.click(await screen.findByRole('button', { name: 'View' }))
    const dialog = await screen.findByRole('dialog', { name: 'Trip details' })
    expect(within(dialog).queryByRole('button', { name: 'Submit report' })).not.toBeInTheDocument()
  })

  it('shows the assigned driver on the tracking timeline', async () => {
    const user = userEvent.setup()
    const trip = tripSummary({
      id: 'trip-assigned',
      status: 'assigned',
      pickup_summary: 'HQ',
      destination_summary: 'Plant',
      tracking: {
        stage: 'driver_assigned',
        rejection_reason: null,
        scheduled_at: '2026-11-04T08:00:00.000Z',
        driver: { name_en: 'Nader Hassan', name_ar: 'نادر حسن', phone: '01099998888' },
        vehicle: { car_license: 'PLATE-9' },
        timeline: [
          {
            stage: 'submitted',
            reached_at: '2026-11-02T10:00:00.000Z',
            actor_role: 'employee',
          },
          {
            stage: 'approved',
            reached_at: '2026-11-02T11:00:00.000Z',
            actor_role: 'company_admin',
          },
          {
            stage: 'driver_assigned',
            reached_at: '2026-11-03T09:00:00.000Z',
            actor_role: 'drivers_admin',
          },
        ],
      },
    })
    http.get.mockImplementation(async (path: string) => {
      if (path === '/my-trips') return paginated([trip])
      if (path === '/trips/trip-assigned') return trip
      if (path === '/places') return paginated(places)
      throw new Error(path)
    })

    renderAs(<MyTripsPage />, 'company_admin')
    expect(await screen.findByText('Driver assigned')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'View' }))
    const dialog = await screen.findByRole('dialog', { name: 'Trip details' })
    expect(within(dialog).getByText('Approved?')).toBeInTheDocument()
    expect(within(dialog).getByText(/Approved /)).toBeInTheDocument()
    expect(within(dialog).getByText(/Nader Hassan/)).toBeInTheDocument()
    expect(within(dialog).getByText(/01099998888/)).toBeInTheDocument()
    expect(within(dialog).getByText(/PLATE-9/)).toBeInTheDocument()
  })

  it('shows a rejection reason on the tracking timeline', async () => {
    const user = userEvent.setup()
    const trip = tripSummary({
      id: 'trip-rejected',
      status: 'cancelled',
      tracking: {
        stage: 'rejected',
        rejection_reason: 'No cars that day',
        driver: null,
        scheduled_at: null,
        vehicle: null,
        timeline: [
          {
            stage: 'submitted',
            reached_at: '2026-11-02T10:00:00.000Z',
            actor_role: 'employee',
          },
          {
            stage: 'rejected',
            reached_at: '2026-11-02T12:00:00.000Z',
            actor_role: 'company_admin',
          },
        ],
      },
    })
    http.get.mockImplementation(async (path: string) => {
      if (path === '/my-trips') return paginated([trip])
      if (path === '/trips/trip-rejected') return trip
      if (path === '/places') return paginated(places)
      throw new Error(path)
    })

    renderAs(<MyTripsPage />, 'company_admin')
    expect(await screen.findByText('Rejected')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'View' }))
    const dialog = await screen.findByRole('dialog', { name: 'Trip details' })
    expect(within(dialog).getByText('Rejection reason')).toBeInTheDocument()
    expect(within(dialog).getByText('No cars that day')).toBeInTheDocument()
  })
})

function renderAs(ui: ReactElement, role: User['role']) {
  const person: User = {
    id: 'user-1',
    name_en: 'Mona',
    name_ar: null,
    email: 'mona@example.com',
    role,
    is_active: true,
    phone: null,
    branch: 'company_headquarters',
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
