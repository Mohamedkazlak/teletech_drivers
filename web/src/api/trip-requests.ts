import { api } from './client'
import { toQuery } from './to-query'
import type {
  Branch,
  DataEnvelope,
  GroupSuggestion,
  Paginated,
  TripRequest,
  TripRequestStage,
  TripRequestStatus,
} from './types'

export type ListTripRequestsQuery = {
  status?: TripRequestStatus
  has_trip?: boolean
  branch?: Branch
  stage?: TripRequestStage
  period?: 'week' | 'month' | 'year'
  date?: string
  date_from?: string
  date_to?: string
  employee_id?: string
  search?: string
  page?: number
  per_page?: number
}

export type PlaceRef = {
  place_id: string
}

export type CreateTripRequestBody = {
  pickup: PlaceRef
  destination: PlaceRef
  requested_at: string
  notes?: string
}

export type RejectTripRequestBody = {
  rejection_reason?: string | null
}

export function listTripRequests(query: ListTripRequestsQuery, signal?: AbortSignal) {
  return api.get<Paginated<TripRequest>>('/trip-requests', { query: toQuery(query), signal })
}

export function getTripRequest(id: string, signal?: AbortSignal) {
  return api.get<TripRequest>(`/trip-requests/${id}`, { signal })
}

export function createTripRequest(body: CreateTripRequestBody) {
  return api.post<TripRequest>('/trip-requests', body)
}

export function approveTripRequest(id: string) {
  return api.post<TripRequest>(`/trip-requests/${id}/approve`)
}

export type ConfirmTripBody = {
  driver_showed_up: boolean
  note?: string
}

export function confirmTrip(requestId: string, body: ConfirmTripBody) {
  return api.post<TripRequest>(`/trip-requests/${requestId}/confirm-trip`, body)
}

export function rejectTripRequest(id: string, body: RejectTripRequestBody) {
  return api.post<TripRequest>(`/trip-requests/${id}/reject`, body)
}

export function approveTripRequestGroup(requestIds: string[]) {
  return api.post<DataEnvelope<TripRequest>>('/trip-requests/approve-group', {
    request_ids: requestIds,
  })
}

export function listGroupingSuggestions(signal?: AbortSignal) {
  return api.get<DataEnvelope<GroupSuggestion>>('/trip-requests/grouping-suggestions', { signal })
}
