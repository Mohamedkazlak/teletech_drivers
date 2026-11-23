import type { Branch, TripListPeriod, TripRequestStatus, TripStage, TripStatus } from './types'
import { PAGE_SIZE } from './to-query'
import type { ListPlacesQuery } from './places'
import type { ListTripRequestsQuery } from './trip-requests'
import type { ListTripsQuery, TripLifecycle } from './trips'
import { tripPeriodParams, type TripPeriod } from '../lib/trip-period'

export type MyTripsTab = 'all' | 'active' | 'completed' | 'cancelled'

export function requestedTripsQuery(input: {
  status: TripRequestStatus
  branch: Branch | ''
  page: number
}): ListTripRequestsQuery {
  return {
    status: input.status,
    branch: input.branch || undefined,
    page: input.page > 1 ? input.page : undefined,
    per_page: PAGE_SIZE,
  }
}

/** GET /my-trips filters with bucket. `all` is sent explicitly and is not filtered again on the client. */
export function myTripsQuery(tab: MyTripsTab, page: number): ListTripsQuery {
  return {
    bucket: tab,
    page: page > 1 ? page : undefined,
    per_page: PAGE_SIZE,
  }
}

export function tripsListQuery(input: {
  branch: Branch | ''
  stage: TripStage | ''
  status: TripStatus | ''
  lifecycle?: TripLifecycle | ''
  period: TripPeriod
  date: string
  page: number
  finishedPeriod?: TripListPeriod | ''
  unconfirmed?: boolean
}): ListTripsQuery {
  return {
    branch: input.branch || undefined,
    stage: input.stage || undefined,
    status: input.status || undefined,
    lifecycle: input.lifecycle || undefined,
    finished_period: input.finishedPeriod || undefined,
    unconfirmed: input.unconfirmed || undefined,
    page: input.page > 1 ? input.page : undefined,
    per_page: PAGE_SIZE,
    ...tripPeriodParams(input.period, input.date),
  }
}

export function placesListQuery(input: { search: string; page: number }): ListPlacesQuery {
  return {
    search: input.search.trim() || undefined,
    page: input.page > 1 ? input.page : undefined,
    per_page: PAGE_SIZE,
  }
}
