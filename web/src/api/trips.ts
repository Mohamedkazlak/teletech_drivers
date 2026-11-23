import { api } from './client'
import { toQuery } from './to-query'
import type {
  Branch,
  DataEnvelope,
  DriverRecommendation,
  Paginated,
  TripCreationMode,
  TripListBucket,
  TripListPeriod,
  TripReport,
  TripStage,
  TripStatus,
  TripSummary,
} from './types'

export type TripLifecycle = 'upcoming' | 'in_progress' | 'completed' | 'cancelled'

export type ListTripsQuery = {
  status?: TripStatus
  stage?: TripStage
  lifecycle?: TripLifecycle
  branch?: Branch
  driver_showed_up?: boolean
  driver_id?: string
  date_from?: string
  date_to?: string
  period?: TripListPeriod
  finished_period?: TripListPeriod
  date?: string
  unconfirmed?: boolean
  /** GET /my-trips. Omitted on GET /trips. */
  bucket?: TripListBucket
  page?: number
  per_page?: number
}

export function listTrips(query: ListTripsQuery, signal?: AbortSignal) {
  return api.get<Paginated<TripSummary>>('/trips', { query: toQuery(query), signal })
}

export function listMyTrips(query: ListTripsQuery, signal?: AbortSignal) {
  return api.get<Paginated<TripSummary>>('/my-trips', { query: toQuery(query), signal })
}

export function getTrip(id: string, signal?: AbortSignal) {
  return api.get<TripSummary>(`/trips/${id}`, { signal })
}

export function getTripReport(id: string, signal?: AbortSignal) {
  return api.get<TripReport>(`/trips/${id}/report`, { signal })
}

export function listDriverRecommendations(tripId: string, signal?: AbortSignal) {
  return api.get<DataEnvelope<DriverRecommendation>>(`/trips/${tripId}/driver-recommendations`, {
    signal,
  })
}

export type CreateTripsBody = {
  mode: TripCreationMode
  request_ids: string[]
  scheduled_at?: string
}

export function createTripsFromRequests(body: CreateTripsBody) {
  return api.post<DataEnvelope<TripSummary>>('/trips/from-requests', body)
}

export function assignTripDriver(tripId: string, driverId: string) {
  return api.post<TripSummary>(`/trips/${tripId}/assign`, { driver_id: driverId })
}

export function cancelTrip(tripId: string) {
  return api.post<TripSummary>(`/trips/${tripId}/cancel`)
}
