import { PAGE_SIZE } from './to-query'
import type { ListTripRequestsQuery } from './trip-requests'
import type { Branch, TripRequestStatus } from './types'

export const REQUEST_PERIODS = ['week', 'month', 'year', 'all'] as const

export type RequestPeriod = (typeof REQUEST_PERIODS)[number]

export function adminTripRequestsQuery(input: {
  status: TripRequestStatus
  branch: Branch | ''
  period: RequestPeriod
  date: string
  page: number
}): ListTripRequestsQuery {
  return {
    status: input.status,
    branch: input.branch || undefined,
    page: input.page > 1 ? input.page : undefined,
    per_page: PAGE_SIZE,
    ...requestPeriodParams(input.period, input.date),
  }
}

function requestPeriodParams(
  period: RequestPeriod,
  date: string,
): Pick<ListTripRequestsQuery, 'period' | 'date'> {
  if (period === 'week' || period === 'month' || period === 'year') return { period, date }
  return {}
}
