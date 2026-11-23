import { act, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../api/client'
import { ApiError } from '../api/errors'
import type { LiveMapDriver } from '../api/types'
import i18n from '../i18n'
import { LIVE_POLL_MS } from '../lib/live-poll'
import { driver, renderPage } from '../test/render-page'
import { LiveMapPage } from './LiveMapPage'

vi.mock('../components/map/MapView', () => ({
  MapView: ({
    markers,
    onSelect,
  }: {
    markers?: Array<{ id: string; label: string }>
    onSelect?: (id: string) => void
  }) => (
    <div>
      {markers?.map((marker) => (
        <button key={marker.id} type="button" onClick={() => onSelect?.(marker.id)}>
          {marker.label}
        </button>
      ))}
    </div>
  ),
}))

vi.mock('../api/client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const http = vi.mocked(api)

function liveCalls() {
  return http.get.mock.calls.filter((call) => call[0] === '/live-map').length
}

function liveDriver(overrides: Partial<LiveMapDriver> = {}): LiveMapDriver {
  return {
    driver: driver(),
    is_available: true,
    state: 'on_trip',
    trip: {
      id: 'trip-9',
      status: 'going',
      pickup_summary: 'HQ',
      destination_summary: 'Site',
      scheduled_at: '2026-11-10T08:00:00.000Z',
      going_started_at: '2026-11-10T08:05:00.000Z',
    },
    lat: 30.05,
    lng: 31.24,
    heading: null,
    speed: null,
    accuracy: 8,
    updated_at: '2026-11-10T10:00:00.000Z',
    last_seen_at: '2026-11-10T10:00:00.000Z',
    is_stale: false,
    is_tracking: true,
    ...overrides,
  }
}

describe('live map', () => {
  beforeEach(() => {
    http.get.mockReset()
  })

  afterEach(async () => {
    vi.useRealTimers()
    await i18n.changeLanguage('en')
    Reflect.deleteProperty(document, 'visibilityState')
  })

  it('shows an empty fleet', async () => {
    http.get.mockResolvedValue({ data: [] })
    renderPage(<LiveMapPage />)
    expect(await screen.findByText('No drivers to show.')).toBeInTheDocument()
    expect(screen.getByText(/Last updated/)).toBeInTheDocument()
  })

  it('shows an error and retries', async () => {
    const user = userEvent.setup()
    http.get.mockRejectedValue(new ApiError('The server failed.', 422))
    renderPage(<LiveMapPage />)
    expect(await screen.findByRole('alert')).toHaveTextContent('The server failed.')

    http.get.mockResolvedValue({ data: [] })
    await user.click(screen.getByRole('button', { name: 'Try again' }))
    expect(await screen.findByText('No drivers to show.')).toBeInTheDocument()
  })

  it('opens a driver card from a marker', async () => {
    const user = userEvent.setup()
    http.get.mockResolvedValue({
      data: [
        liveDriver(),
        liveDriver({
          driver: driver({
            id: 'driver-2',
            name_en: 'Huda Samir',
            name_ar: 'هدى سمير',
            phone: null,
          }),
          state: 'unavailable',
          is_available: false,
          trip: null,
          lat: null,
          lng: null,
        }),
      ],
    })
    renderPage(<LiveMapPage />)
    await user.click(await screen.findByRole('button', { name: 'Nader Ali' }))
    const card = await screen.findByRole('region', { name: 'Driver' })
    expect(card).toHaveTextContent('01011111111')
    expect(card).toHaveTextContent('On trip')
    expect(card).toHaveTextContent('HQ to Site')
    expect(screen.getByText('Huda Samir')).toBeInTheDocument()
    expect(screen.getByText('No location yet')).toBeInTheDocument()
  })

  it('polls while the tab is visible, pauses when hidden, and stops on unmount', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    let visibility: DocumentVisibilityState = 'visible'
    Object.defineProperty(document, 'visibilityState', {
      configurable: true,
      get: () => visibility,
    })
    http.get.mockResolvedValue({ data: [liveDriver()] })

    const view = renderPage(<LiveMapPage />)
    await waitFor(() => expect(liveCalls()).toBeGreaterThanOrEqual(1))
    const started = liveCalls()
    await vi.advanceTimersByTimeAsync(LIVE_POLL_MS)
    await waitFor(() => expect(liveCalls()).toBeGreaterThan(started))

    visibility = 'hidden'
    await act(async () => {
      document.dispatchEvent(new Event('visibilitychange'))
    })
    const paused = liveCalls()
    await vi.advanceTimersByTimeAsync(LIVE_POLL_MS * 3)
    expect(liveCalls()).toBe(paused)

    visibility = 'visible'
    await act(async () => {
      document.dispatchEvent(new Event('visibilitychange'))
    })
    await vi.advanceTimersByTimeAsync(LIVE_POLL_MS)
    await waitFor(() => expect(liveCalls()).toBeGreaterThan(paused))

    const running = liveCalls()
    view.unmount()
    await vi.advanceTimersByTimeAsync(LIVE_POLL_MS * 3)
    expect(liveCalls()).toBe(running)
  })
})
