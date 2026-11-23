import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useForegroundPoll } from '../lib/use-foreground-poll'
import { retryTransient } from './retry'
import { tripKeys } from './use-trips'
import {
  approveTripRequest,
  approveTripRequestGroup,
  confirmTrip,
  createTripRequest,
  getTripRequest,
  listGroupingSuggestions,
  listTripRequests,
  rejectTripRequest,
  type CreateTripRequestBody,
  type ListTripRequestsQuery,
  type RejectTripRequestBody,
} from './trip-requests'

export const tripRequestKeys = {
  all: ['trip-requests'] as const,
  list: (query: ListTripRequestsQuery) => ['trip-requests', 'list', query] as const,
  detail: (id: string) => ['trip-requests', 'detail', id] as const,
  suggestions: ['trip-requests', 'grouping-suggestions'] as const,
}

function invalidateTripRequests(queryClient: ReturnType<typeof useQueryClient>) {
  void queryClient.invalidateQueries({ queryKey: tripRequestKeys.all })
  void queryClient.invalidateQueries({ queryKey: ['my-trips'] })
}

export function useTripRequests(query: ListTripRequestsQuery) {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: tripRequestKeys.list(query),
    queryFn: ({ signal }) => listTripRequests(query, signal),
    refetchInterval: pollMs,
    refetchIntervalInBackground: false,
    retry: retryTransient,
  })
}

export function useTripRequest(id: string | null) {
  return useQuery({
    queryKey: tripRequestKeys.detail(id ?? ''),
    queryFn: ({ signal }) => getTripRequest(id ?? '', signal),
    enabled: Boolean(id),
    retry: retryTransient,
  })
}

export function useGroupingSuggestions(enabled: boolean) {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: tripRequestKeys.suggestions,
    queryFn: ({ signal }) => listGroupingSuggestions(signal),
    enabled,
    refetchInterval: enabled ? pollMs : false,
    refetchIntervalInBackground: false,
    retry: retryTransient,
  })
}

export function useCreateTripRequest() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (body: CreateTripRequestBody) => createTripRequest(body),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['my-trips'] })
      void invalidateTripRequests(queryClient)
    },
  })
}

export function useConfirmTrip() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({
      requestId,
      driverShowedUp,
      note,
    }: {
      requestId: string
      driverShowedUp: boolean
      note?: string
    }) =>
      confirmTrip(requestId, {
        driver_showed_up: driverShowedUp,
        ...(note == null || note === '' ? {} : { note }),
      }),
    onSettled: () => {
      void queryClient.invalidateQueries({ queryKey: ['my-trips'] })
      void queryClient.invalidateQueries({ queryKey: tripKeys.all })
    },
  })
}

export function useApproveTripRequest() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => approveTripRequest(id),
    onSuccess: () => invalidateTripRequests(queryClient),
  })
}

export function useRejectTripRequest() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: RejectTripRequestBody }) =>
      rejectTripRequest(id, body),
    onSuccess: () => invalidateTripRequests(queryClient),
  })
}

export function useApproveGroup() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (requestIds: string[]) => approveTripRequestGroup(requestIds),
    onSuccess: () => invalidateTripRequests(queryClient),
  })
}
