import type { TripListPeriod } from '../api/types'
import type { PeriodKind } from './period'

/**
 * GET /trips accepts `day`, `week`, `month`, and `custom`.
 * `year` is not a trip-list period. `all` means no window, so the query omits `period`.
 */
export const TRIP_PERIODS = ['day', 'week', 'month', 'all'] as const

export type TripPeriod = (typeof TRIP_PERIODS)[number]

export function readTripPeriod(value: string | null): TripPeriod {
  if (value === 'day' || value === 'week' || value === 'month' || value === 'all') return value
  return 'week'
}

export function readFinishedPeriod(value: string | null): TripListPeriod | '' {
  if (value === 'day' || value === 'week' || value === 'month' || value === 'custom') return value
  return ''
}

/** Dashboard links use `unconfirmed=true`. Other values stay off so the list is unchanged. */
export function readUnconfirmedParam(value: string | null): boolean {
  return value === 'true' || value === '1'
}

export function tripPeriodParams(
  period: PeriodKind,
  date: string,
): { period?: TripListPeriod; date?: string } {
  if (period === 'day' || period === 'week' || period === 'month') {
    return { period, date }
  }
  return {}
}
