import { useMutation, useQuery, useQueryClient, useQueries } from '@tanstack/react-query'
import { LIVE_POLL_MS } from '../lib/live-poll'
import { useForegroundPoll } from '../lib/use-foreground-poll'
import { isTripInProgress } from '../lib/trip-actions'
import { retryTransient } from './retry'
import {
  assignTripDriver,
  cancelTrip,
  createTripsFromRequests,
  getTrip,
  getTripReport,
  listDriverRecommendations,
  listMyTrips,
  listTrips,
  type CreateTripsBody,
  type ListTripsQuery,
} from './trips'
import type { TripStage } from './types'

export const tripKeys = {
  all: ['trips'] as const,
  list: (query: ListTripsQuery) => ['trips', 'list', query] as const,
  detail: (id: string) => ['trips', 'detail', id] as const,
  report: (id: string) => ['trips', 'report', id] as const,
  recommendations: (id: string) => ['trips', 'recommendations', id] as const,
  mine: (query: ListTripsQuery) => ['my-trips', 'list', query] as const,
}

function invalidateFleet(queryClient: ReturnType<typeof useQueryClient>) {
  void queryClient.invalidateQueries({ queryKey: tripKeys.all })
  void queryClient.invalidateQueries({ queryKey: ['my-trips'] })
  void queryClient.invalidateQueries({ queryKey: ['trip-requests'] })
}

const OVERVIEW_STAGES = ['unassigned', 'assigned', 'in_progress', 'completed'] as const

export function useTrips(query: ListTripsQuery) {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: tripKeys.list(query),
    queryFn: ({ signal }) => listTrips(query, signal),
    refetchInterval: pollMs,
    refetchIntervalInBackground: false,
    retry: retryTransient,
  })
}

export function useMyTrips(query: ListTripsQuery) {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: tripKeys.mine(query),
    queryFn: ({ signal }) => listMyTrips(query, signal),
    refetchInterval: pollMs,
    refetchIntervalInBackground: false,
    retry: retryTransient,
  })
}

export function useTrip(
  id: string | null,
  options?: { pollWhileInProgress?: boolean; poll?: boolean },
) {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: tripKeys.detail(id ?? ''),
    queryFn: ({ signal }) => getTrip(id ?? '', signal),
    enabled: Boolean(id),
    retry: retryTransient,
    refetchInterval: options?.poll
      ? pollMs
      : options?.pollWhileInProgress
        ? (query) =>
            pollMs !== false && isTripInProgress(query.state.data?.status) ? LIVE_POLL_MS : false
        : false,
    refetchIntervalInBackground: false,
  })
}

export function useTripReport(id: string | null) {
  return useQuery({
    queryKey: tripKeys.report(id ?? ''),
    queryFn: ({ signal }) => getTripReport(id ?? '', signal),
    enabled: Boolean(id),
    retry: retryTransient,
  })
}

export function useDriverRecommendations(tripId: string | null) {
  return useQuery({
    queryKey: tripKeys.recommendations(tripId ?? ''),
    queryFn: ({ signal }) => listDriverRecommendations(tripId ?? '', signal),
    enabled: Boolean(tripId),
    retry: retryTransient,
  })
}

export function useCreateTrips() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (body: CreateTripsBody) => createTripsFromRequests(body),
    onSuccess: () => invalidateFleet(queryClient),
  })
}

export function useAssignTrip() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ tripId, driverId }: { tripId: string; driverId: string }) =>
      assignTripDriver(tripId, driverId),
    onSuccess: () => invalidateFleet(queryClient),
  })
}

export function useCancelTrip() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (tripId: string) => cancelTrip(tripId),
    onSuccess: () => invalidateFleet(queryClient),
  })
}

export function useTripOverview(
  base: Omit<ListTripsQuery, 'stage' | 'status' | 'page' | 'per_page'>,
) {
  const pollMs = useForegroundPoll()
  return useQueries({
    queries: OVERVIEW_STAGES.map((stage) => {
      const query: ListTripsQuery = { ...base, stage, page: 1, per_page: 1 }
      return {
        queryKey: tripKeys.list(query),
        queryFn: ({ signal }: { signal: AbortSignal }) => listTrips(query, signal),
        refetchInterval: pollMs,
        refetchIntervalInBackground: false,
        retry: retryTransient,
      }
    }),
  })
}

export function overviewStage(index: number): TripStage {
  return OVERVIEW_STAGES[index] ?? 'unassigned'
}
