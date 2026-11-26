import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import { ApiError } from '../../api/errors'
import i18n from '../../i18n'
import { paginated, renderPage, tripSummary } from '../../test/render-page'
import { TripsPage } from './TripsPage'

vi.mock('../../components/map/MapView', () => ({
  MapView: ({ paths }: { paths?: unknown[] }) => (
    <div data-testid="map" data-paths={String(paths?.length ?? 0)} />
  ),
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

function tripQueries() {
  return http.get.mock.calls
    .filter((call) => call[0] === '/trips')
    .map((call) => (call[1] as { query?: Record<string, unknown> }).query)
}

describe('company trips', () => {
  beforeEach(async () => {
    http.get.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockResolvedValue(paginated([]))
  })

  it('sends the Cairo week and branch filter to GET /trips', async () => {
    const user = userEvent.setup()
    renderPage(<TripsPage />, '/?period=week&date=2026-11-11&stage=in_progress')

    await waitFor(() => {
      expect(tripQueries()).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            stage: 'in_progress',
            per_page: 15,
            period: 'week',
            date: '2026-11-11',
          }),
        ]),
      )
    })
    expect(tripQueries().some((query) => query && 'date_from' in query)).toBe(false)
    expect(screen.getByRole('combobox', { name: 'Trip status' })).toBeInTheDocument()
    expect(screen.queryByRole('combobox', { name: 'Stage' })).not.toBeInTheDocument()
    expect(screen.queryByRole('combobox', { name: 'Status' })).not.toBeInTheDocument()

    await user.selectOptions(screen.getByRole('combobox', { name: 'Branch' }), 'New Headquarters')

    await waitFor(() => {
      expect(tripQueries()).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            stage: 'in_progress',
            branch: 'new_headquarters',
            per_page: 15,
            period: 'week',
            date: '2026-11-11',
          }),
        ]),
      )
    })
  })

  it('lists trips as When, Route, Driver, Phase', async () => {
    renderPage(<TripsPage />, '/?period=week&date=2026-11-11')
    await waitFor(() => {
      expect(screen.getAllByRole('columnheader').map((cell) => cell.textContent)).toEqual([
        'When',
        'Route',
        'Driver',
        'Phase',
        'Actions',
      ])
    })
  })

  it('applies finished_period and unconfirmed without the default scheduled week', async () => {
    const finished = renderPage(<TripsPage />, '/admin/trips?stage=completed&finished_period=day')

    await waitFor(() => {
      expect(tripQueries()).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            stage: 'completed',
            finished_period: 'day',
            per_page: 15,
          }),
        ]),
      )
    })
    expect(tripQueries().some((query) => query?.finished_period === 'day')).toBe(true)
    expect(tripQueries().every((query) => query !== undefined && !('period' in query))).toBe(true)
    finished.unmount()

    http.get.mockClear()
    renderPage(<TripsPage />, '/admin/trips?unconfirmed=true')

    await waitFor(() => {
      expect(tripQueries()).toEqual(
        expect.arrayContaining([expect.objectContaining({ unconfirmed: true, per_page: 15 })]),
      )
    })
    expect(
      tripQueries().every((query) => query?.unconfirmed === true && !('period' in query)),
    ).toBe(true)
    expect(
      tripQueries().every((query) => query !== undefined && !('finished_period' in query)),
    ).toBe(true)
  })

  it('shows a retry when the stage counts fail', async () => {
    http.get.mockRejectedValue(new ApiError('The server failed.', 422))
    renderPage(<TripsPage />)
    const alerts = await screen.findAllByRole('alert')
    expect(alerts.some((alert) => alert.textContent?.includes('The server failed.'))).toBe(true)
    expect(screen.getAllByRole('button', { name: 'Try again' }).length).toBeGreaterThan(1)
  })

  it('loads the trip report and draws driven_route only when it has points', async () => {
    const user = userEvent.setup()
    const trip = tripSummary({
      id: 'trip-1',
      status: 'completed',
      confirmation_status: 'unconfirmed',
      driver_showed_up: true,
      confirmation_note: 'Traffic',
      going_distance_m: null,
    })
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trips/trip-1/report') {
        return {
          status: 'completed',
          is_in_progress: false,
          start: '2026-11-11T08:00:00.000Z',
          finish: '2026-11-11T09:00:00.000Z',
          going_duration_seconds: 1800,
          waiting_duration_seconds: 600,
          return_duration_seconds: 1200,
          total_duration_seconds: 3600,
          going_distance_km: 12.5,
          return_distance_km: 11,
          total_distance_km: 23.5,
          going_route: null,
          return_route: null,
          driven_route: [],
        }
      }
      if (path === '/trips/trip-1') return trip
      if (path === '/trips') return paginated([trip])
      throw new Error(path)
    })

    renderPage(<TripsPage />)
    await user.click(await screen.findByRole('button', { name: 'View' }))
    const dialog = await screen.findByRole('dialog', { name: 'Trip details' })

    expect(await within(dialog).findByText('12.5 km')).toBeInTheDocument()
    expect(within(dialog).getByText('Unconfirmed')).toBeInTheDocument()
    expect(within(dialog).getByText('Traffic')).toBeInTheDocument()
    expect(within(dialog).queryByTestId('map')).not.toBeInTheDocument()
    expect(http.get).toHaveBeenCalledWith('/trips/trip-1/report', expect.anything())
  })

  it('draws the driven route when the report includes points', async () => {
    const user = userEvent.setup()
    const trip = tripSummary({ id: 'trip-1', status: 'completed' })
    http.get.mockImplementation(async (path: string) => {
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
          driven_route: [{ lat: 30.1, lng: 31.2, recorded_at: '2026-11-11T08:05:00.000Z' }],
        }
      }
      if (path === '/trips/trip-1') return trip
      if (path === '/trips') return paginated([trip])
      throw new Error(path)
    })

    renderPage(<TripsPage />)
    await user.click(await screen.findByRole('button', { name: 'View' }))
    const dialog = await screen.findByRole('dialog', { name: 'Trip details' })
    expect(await within(dialog).findByTestId('map')).toHaveAttribute('data-paths', '1')
  })

  it('sends one trip status filter', async () => {
    const user = userEvent.setup()
    renderPage(<TripsPage />)

    await user.selectOptions(screen.getByRole('combobox', { name: 'Trip status' }), 'In progress')

    await waitFor(() => {
      expect(tripQueries()).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ lifecycle: 'in_progress', per_page: 15 }),
        ]),
      )
    })
    const lifecycleQueries = tripQueries().filter(
      (query) => query?.lifecycle === 'in_progress',
    )
    expect(lifecycleQueries.length).toBeGreaterThan(0)
    expect(lifecycleQueries.every((query) => query && !('stage' in query))).toBe(true)
    expect(lifecycleQueries.every((query) => query && !('status' in query))).toBe(true)
  })
})
