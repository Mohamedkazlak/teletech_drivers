import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { retryTransient } from './retry'
import {
  createDriver,
  deleteDriver,
  getDriver,
  restoreDriver,
  getDriverStats,
  listAllDrivers,
  listDriverTrips,
  listDrivers,
  updateDriver,
  type CreateDriverBody,
  type DriverStatsQuery,
  type ListDriverTripsQuery,
  type ListDriversQuery,
  type UpdateDriverBody,
} from './drivers'

export const driverKeys = {
  all: ['drivers'] as const,
  list: (query: ListDriversQuery) => ['drivers', 'list', query] as const,
  detail: (id: string) => ['drivers', 'detail', id] as const,
  stats: (id: string, query: DriverStatsQuery) => ['drivers', id, 'stats', query] as const,
  trips: (id: string, query: ListDriverTripsQuery) => ['drivers', id, 'trips', query] as const,
  roster: ['drivers', 'roster'] as const,
}

function invalidateDrivers(queryClient: ReturnType<typeof useQueryClient>) {
  void queryClient.invalidateQueries({ queryKey: driverKeys.all })
}

export function useDrivers(query: ListDriversQuery) {
  return useQuery({
    queryKey: driverKeys.list(query),
    queryFn: ({ signal }) => listDrivers(query, signal),
    retry: retryTransient,
  })
}

export function useDriverRoster(enabled: boolean) {
  return useQuery({
    queryKey: driverKeys.roster,
    queryFn: ({ signal }) => listAllDrivers(signal),
    enabled,
    retry: retryTransient,
  })
}

export function useDriver(id: string) {
  return useQuery({
    queryKey: driverKeys.detail(id),
    queryFn: ({ signal }) => getDriver(id, signal),
    enabled: Boolean(id),
    retry: retryTransient,
  })
}

export function useDriverStats(id: string, query: DriverStatsQuery) {
  return useQuery({
    queryKey: driverKeys.stats(id, query),
    queryFn: ({ signal }) => getDriverStats(id, query, signal),
    enabled: Boolean(id),
    retry: retryTransient,
  })
}

export function useDriverTrips(id: string, query: ListDriverTripsQuery) {
  return useQuery({
    queryKey: driverKeys.trips(id, query),
    queryFn: ({ signal }) => listDriverTrips(id, query, signal),
    enabled: Boolean(id),
    retry: retryTransient,
  })
}

export function useCreateDriver() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (body: CreateDriverBody) => createDriver(body),
    onSuccess: () => invalidateDrivers(queryClient),
  })
}

export function useUpdateDriver() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: UpdateDriverBody }) => updateDriver(id, body),
    onSuccess: () => invalidateDrivers(queryClient),
  })
}

export function useDeleteDriver() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => deleteDriver(id),
    onSuccess: () => invalidateDrivers(queryClient),
  })
}

export function useRestoreDriver() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => restoreDriver(id),
    onSuccess: () => invalidateDrivers(queryClient),
  })
}
