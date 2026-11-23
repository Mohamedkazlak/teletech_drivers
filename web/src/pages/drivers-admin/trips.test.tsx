import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import i18n from '../../i18n'
import { LIVE_POLL_MS } from '../../lib/live-poll'
import { paginated, renderPage, tripSummary } from '../../test/render-page'
import { TripsPage } from './TripsPage'

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

function tripQueries() {
  return http.get.mock.calls
    .filter((call) => call[0] === '/trips')
    .map((call) => (call[1] as { query?: Record<string, unknown> }).query)
}

function liveMapCalls() {
  return http.get.mock.calls.filter((call) => call[0] === '/live-map').length
}

const emptyReport = {
  status: 'going',
  is_in_progress: true,
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

describe('drivers admin trips', () => {
  beforeEach(async () => {
    http.get.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockResolvedValue(paginated([]))
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('sends the stage tabs, branch, and period', async () => {
    const user = userEvent.setup()
    renderPage(<TripsPage />, '/?period=week&date=2026-11-11')

    await waitFor(() => {
      expect(tripQueries()).toContainEqual({
        stage: 'unassigned',
        period: 'week',
        date: '2026-11-11',
        per_page: 15,
      })
    })

    await user.selectOptions(screen.getByRole('combobox', { name: 'Stage' }), 'Assigned')
    await waitFor(() => {
      expect(tripQueries()).toContainEqual({
        stage: 'assigned',
        period: 'week',
        date: '2026-11-11',
        per_page: 15,
      })
    })

    await user.selectOptions(screen.getByRole('combobox', { name: 'Stage' }), 'In progress')
    await user.selectOptions(screen.getByRole('combobox', { name: 'Stage' }), 'Completed')
    await user.selectOptions(screen.getByRole('combobox', { name: 'Branch' }), 'New Headquarters')

    await waitFor(() => {
      expect(tripQueries()).toContainEqual({
        stage: 'completed',
        branch: 'new_headquarters',
        period: 'week',
        date: '2026-11-11',
        per_page: 15,
      })
    })
    expect(tripQueries()).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ stage: 'in_progress', period: 'week', date: '2026-11-11' }),
      ]),
    )
  })

  it('polls the driver location while the in-progress dialog is open and stops on close', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
    const trip = tripSummary({
      id: 'trip-1',
      status: 'going',
      driver_id: 'driver-1',
      driver: {
        id: 'driver-1',
        name_en: 'Nader',
        name_ar: null,
        email: 'nader@example.com',
        role: 'driver',
        is_active: true,
        phone: null,
        is_available: true,
            favorite_place_ids: [],
        deleted_at: null,
        deleted_by: null,
      },
    })
    http.get.mockImplementation(async (path: string) => {
      if (path === '/live-map') {
        return {
          data: [
            {
              lat: 30.05,
              lng: 31.24,
            },
          ],
        }
      }
      if (path === '/trips/trip-1/report') return emptyReport
      if (path === '/trips/trip-1') return trip
      if (path === '/trips') return paginated([trip])
      throw new Error(path)
    })

    renderPage(<TripsPage />, '/?stage=in_progress')
    await user.click(await screen.findByRole('button', { name: 'View' }))
    const dialog = await screen.findByRole('dialog', { name: 'Trip details' })

    await waitFor(() => expect(liveMapCalls()).toBeGreaterThanOrEqual(1))
    const started = liveMapCalls()
    await vi.advanceTimersByTimeAsync(LIVE_POLL_MS)
    await waitFor(() => expect(liveMapCalls()).toBeGreaterThan(started))

    await user.click(within(dialog).getByRole('button', { name: 'Close' }))
    await waitFor(() => {
      expect(screen.queryByRole('dialog', { name: 'Trip details' })).not.toBeInTheDocument()
    })
    const stopped = liveMapCalls()
    await vi.advanceTimersByTimeAsync(LIVE_POLL_MS * 3)
    expect(liveMapCalls()).toBe(stopped)
  })
})
