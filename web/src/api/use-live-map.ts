import { useQuery } from '@tanstack/react-query'
import { useForegroundPoll } from '../lib/use-foreground-poll'
import { listLiveMap } from './live-map'
import { retryTransient } from './retry'

export const fleetLiveMapKey = ['live-map', 'fleet'] as const

/** Polls the fleet map while the tab is visible. Location events move markers sooner. */
export function useFleetLiveMap() {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: fleetLiveMapKey,
    queryFn: ({ signal }) => listLiveMap({}, signal),
    refetchInterval: pollMs,
    refetchIntervalInBackground: false,
    refetchOnWindowFocus: false,
    retry: retryTransient,
  })
}

export function useDriverLocation(driverId: string | null) {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: ['live-map', 'driver', driverId ?? ''],
    queryFn: ({ signal }) => listLiveMap({ driver_id: driverId ?? undefined }, signal),
    enabled: Boolean(driverId),
    refetchInterval: pollMs,
    refetchIntervalInBackground: false,
    refetchOnWindowFocus: false,
    retry: retryTransient,
  })
}
