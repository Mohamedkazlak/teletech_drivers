import { addDays, addMonths, addWeeks, addYears, endOfWeek, startOfWeek } from 'date-fns'

export const FLEET_WEEK = { weekStartsOn: 6 as const }

export type PeriodKind = 'day' | 'week' | 'month' | 'year' | 'all'

export type PeriodSelection = {
  period: PeriodKind
  date?: string
}

export function parseDateParam(value: string): Date {
  const [year, month, day] = value.split('-').map(Number)
  return new Date(year || 1970, (month || 1) - 1, day || 1)
}

export function formatDateParam(date: Date): string {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

export function startOfFleetWeek(date: Date): Date {
  return startOfWeek(date, FLEET_WEEK)
}

export function endOfFleetWeek(date: Date): Date {
  return endOfWeek(date, FLEET_WEEK)
}

export function shiftAnchor(
  period: Exclude<PeriodKind, 'all'>,
  anchor: Date,
  direction: -1 | 1,
): Date {
  if (period === 'day') return addDays(anchor, direction)
  if (period === 'week') return addWeeks(anchor, direction)
  if (period === 'month') return addMonths(anchor, direction)
  return addYears(anchor, direction)
}
