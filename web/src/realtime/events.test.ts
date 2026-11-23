import { QueryClient } from '@tanstack/react-query'
import { describe, expect, it } from 'vitest'
import { attendanceKeys } from '../api/use-attendance'
import { fleetLiveMapKey } from '../api/use-live-map'
import { tripRequestKeys } from '../api/use-trip-requests'
import { tripKeys } from '../api/use-trips'
import type { DataEnvelope, LiveMapDriver } from '../api/types'
import { driver } from '../test/render-page'
import { applyRealtimeEvent } from './events'

function locatedDriver(): LiveMapDriver {
  return {
    driver: driver(),
    is_available: true,
    state: 'on_trip',
    trip: null,
    lat: 30,
    lng: 31,
    heading: null,
    speed: null,
    accuracy: 8,
    updated_at: '2026-11-10T10:00:00.000Z',
    last_seen_at: '2026-11-10T10:00:00.000Z',
    is_stale: false,
    is_tracking: true,
  }
}

describe('realtime invalidation', () => {
  it('refetches trip requests when an employee request is created', () => {
    const queryClient = new QueryClient()
    const invalidated: unknown[][] = []
    queryClient.invalidateQueries = (async (filters) => {
      invalidated.push([...(filters?.queryKey ?? [])])
      return Promise.resolve()
    }) as typeof queryClient.invalidateQueries

    applyRealtimeEvent(queryClient, 'trip-request.created', { id: 'req-1', status: 'pending' })

    expect(invalidated).toContainEqual([...tripRequestKeys.all])
    expect(invalidated).toContainEqual([...tripKeys.all])
    expect(invalidated).toContainEqual(['my-trips'])
    expect(invalidated).toContainEqual(['admin-dashboard'])
  })

  it('refetches trips and requests when a trip is approved into the fleet', () => {
    const queryClient = new QueryClient()
    const invalidated: unknown[][] = []
    queryClient.invalidateQueries = (async (filters) => {
      invalidated.push([...(filters?.queryKey ?? [])])
      return Promise.resolve()
    }) as typeof queryClient.invalidateQueries

    applyRealtimeEvent(queryClient, 'trip.assigned', { id: 'trip-1', status: 'assigned' })

    expect(invalidated).toContainEqual([...tripKeys.all])
    expect(invalidated).toContainEqual([...tripRequestKeys.all])
  })

  it('refetches attendance when a driver checks in', () => {
    const queryClient = new QueryClient()
    const invalidated: unknown[][] = []
    queryClient.invalidateQueries = (async (filters) => {
      invalidated.push([...(filters?.queryKey ?? [])])
      return Promise.resolve()
    }) as typeof queryClient.invalidateQueries

    applyRealtimeEvent(queryClient, 'attendance.checked_in', { id: 'log-1', status: 'checked_in' })

    expect(invalidated).toContainEqual([...attendanceKeys.all])
  })

  it('moves a live-map marker from a location event without refetching', () => {
    const queryClient = new QueryClient()
    const envelope: DataEnvelope<LiveMapDriver> = { data: [locatedDriver()] }
    queryClient.setQueryData(fleetLiveMapKey, envelope)
    let invalidated = false
    queryClient.invalidateQueries = (async () => {
      invalidated = true
      return Promise.resolve()
    }) as typeof queryClient.invalidateQueries

    applyRealtimeEvent(queryClient, 'driver-location.updated', {
      id: 'driver-1',
      status: 'tracking',
      lat: 30.5,
      lng: 31.5,
    })

    const next = queryClient.getQueryData<DataEnvelope<LiveMapDriver>>(fleetLiveMapKey)
    expect(next?.data[0]?.lat).toBe(30.5)
    expect(next?.data[0]?.lng).toBe(31.5)
    expect(invalidated).toBe(false)
  })
})
