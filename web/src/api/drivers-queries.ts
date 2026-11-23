import type { Branch } from './types'
import { PAGE_SIZE } from './to-query'
import type { ListTripRequestsQuery } from './trip-requests'
import type { ListTripsQuery } from './trips'
import { tripPeriodParams, type TripPeriod } from '../lib/trip-period'

export type DriversRequestTab = 'pending' | 'approved'

export function driversRequestsQuery(input: {
  tab: DriversRequestTab
  branch: Branch | ''
  page: number
}): ListTripRequestsQuery {
  return {
    has_trip: input.tab === 'approved',
    branch: input.branch || undefined,
    page: input.page > 1 ? input.page : undefined,
    per_page: PAGE_SIZE,
  }
}

export const DRIVERS_TRIP_TABS = ['unassigned', 'assigned', 'in_progress', 'completed'] as const

export type DriversTripTab = (typeof DRIVERS_TRIP_TABS)[number]

export function driversTripsQuery(input: {
  tab: DriversTripTab
  branch: Branch | ''
  period: TripPeriod
  date: string
  page: number
}): ListTripsQuery {
  return {
    stage: input.tab,
    branch: input.branch || undefined,
    page: input.page > 1 ? input.page : undefined,
    per_page: PAGE_SIZE,
    ...tripPeriodParams(input.period, input.date),
  }
}
