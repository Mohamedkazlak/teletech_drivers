import type { QueryClient } from '@tanstack/react-query'
import { attendanceKeys } from '../api/use-attendance'
import { fleetLiveMapKey } from '../api/use-live-map'
import { tripRequestKeys } from '../api/use-trip-requests'
import { tripKeys } from '../api/use-trips'
import type { DataEnvelope, LiveMapDriver } from '../api/types'

export const REALTIME_EVENTS = [
  'trip-request.created',
  'trip-request.updated',
  'trip-request.approved',
  'trip-request.rejected',
  'trip.created',
  'trip.assigned',
  'trip.started',
  'trip.phase-changed',
  'trip.ended',
  'trip.confirmed',
  'trip.cancelled',
  'attendance.checked_in',
  'attendance.checked_out',
  'attendance.adjusted',
  'driver-location.updated',
] as const

export type RealtimeEventName = (typeof REALTIME_EVENTS)[number]

export type RealtimePayload = {
  id?: string
  status?: string
  trip_id?: string | null
  lat?: number
  lng?: number
}

const dashboardKey = ['admin-dashboard'] as const

/** Query keys a fleet event should refetch. Location events update the map directly. */
export function queryKeysForEvent(eventName: string): ReadonlyArray<readonly unknown[]> {
  if (eventName.startsWith('trip-request.')) {
    return [tripRequestKeys.all, tripKeys.all, ['my-trips'], dashboardKey]
  }
  if (eventName.startsWith('trip.')) {
    return [tripKeys.all, ['my-trips'], tripRequestKeys.all, dashboardKey]
  }
  if (eventName.startsWith('attendance.')) {
    return [attendanceKeys.all, dashboardKey]
  }
  return []
}

export function applyRealtimeEvent(
  queryClient: QueryClient,
  eventName: string,
  payload: RealtimePayload,
): void {
  if (eventName === 'driver-location.updated') {
    patchLiveMap(queryClient, payload)
    return
  }
  for (const queryKey of queryKeysForEvent(eventName)) {
    void queryClient.invalidateQueries({ queryKey })
  }
}

function patchLiveMap(queryClient: QueryClient, payload: RealtimePayload): void {
  const driverId = payload.id
  if (!driverId || payload.lat == null || payload.lng == null) {
    void queryClient.invalidateQueries({ queryKey: fleetLiveMapKey })
    return
  }
  const patched = patchEnvelope(queryClient.getQueryData(fleetLiveMapKey), driverId, payload)
  if (patched == null) {
    void queryClient.invalidateQueries({ queryKey: fleetLiveMapKey })
  } else {
    queryClient.setQueryData(fleetLiveMapKey, patched)
  }
  const driverKey = ['live-map', 'driver', driverId] as const
  const driverPatched = patchEnvelope(queryClient.getQueryData(driverKey), driverId, payload)
  if (driverPatched != null) {
    queryClient.setQueryData(driverKey, driverPatched)
  }
}

function patchEnvelope(
  current: DataEnvelope<LiveMapDriver> | undefined,
  driverId: string,
  payload: RealtimePayload,
): DataEnvelope<LiveMapDriver> | null {
  if (!current) return null
  const index = current.data.findIndex((driver) => driver.driver.id === driverId)
  if (index < 0) return null
  const next = current.data.slice()
  const driver = next[index]
  if (!driver) return null
  next[index] = {
    ...driver,
    lat: payload.lat ?? driver.lat,
    lng: payload.lng ?? driver.lng,
    is_tracking: payload.status !== 'stopped',
    is_stale: false,
    updated_at: new Date().toISOString(),
  }
  return { ...current, data: next }
}
