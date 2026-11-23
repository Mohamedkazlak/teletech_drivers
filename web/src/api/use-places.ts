import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  createPlace,
  listActivePlaces,
  listPlaces,
  updatePlace,
  deletePlace,
  type CreatePlaceBody,
  type ListPlacesQuery,
  type UpdatePlaceBody,
} from './places'
import { retryTransient } from './retry'

export const placeKeys = {
  all: ['places'] as const,
  list: (query: ListPlacesQuery) => ['places', 'list', query] as const,
  active: ['places', 'active'] as const,
}

export function usePlaces(query: ListPlacesQuery) {
  return useQuery({
    queryKey: placeKeys.list(query),
    queryFn: ({ signal }) => listPlaces(query, signal),
    retry: retryTransient,
  })
}

export function useActivePlaces(enabled: boolean) {
  return useQuery({
    queryKey: placeKeys.active,
    queryFn: ({ signal }) => listActivePlaces(signal),
    enabled,
    retry: retryTransient,
  })
}

export function useCreatePlace() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (body: CreatePlaceBody) => createPlace(body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: placeKeys.all }),
  })
}

export function useUpdatePlace() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: UpdatePlaceBody }) => updatePlace(id, body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: placeKeys.all }),
  })
}

export function useDeletePlace() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => deletePlace(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: placeKeys.all }),
  })
}
