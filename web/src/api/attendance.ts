import { api } from './client'
import { PAGE_SIZE, toQuery } from './to-query'
import type { Paginated } from './types'

export type AttendancePeriod = 'week' | 'month' | 'year'
export type AttendanceStatus = 'present' | 'absent' | 'checked_in' | 'checked_out'

export type AttendanceDay = {
  driver_id: string
  driver_name_en: string | null
  driver_name_ar: string | null
  work_date: string
  status: 'checked_in' | 'checked_out' | 'absent' | string
  checked_in_at: string | null
  checked_out_at: string | null
  on_site_hours: number | null
  source: string | null
  adjustment_reason: string | null
}

export type AttendanceTotals = {
  days_present: number
  days_absent: number
  total_on_site_hours: number
}

export type AttendancePage = Paginated<AttendanceDay> & {
  totals: AttendanceTotals
}

export type AttendanceSummaryRow = {
  id: string
  name_en: string | null
  name_ar: string | null
  status: string
  checked_in_at: string | null
  checked_out_at: string | null
}

export type AttendanceSummary = {
  work_date: string
  off_day: boolean
  counts: {
    present: number
    checked_in: number
    checked_out: number
    absent: number
  }
  present: AttendanceSummaryRow[]
  checked_in: AttendanceSummaryRow[]
  checked_out: AttendanceSummaryRow[]
  absent: AttendanceSummaryRow[]
}

export type AttendanceQr = {
  payload: string
  hq_name: string
  version: number
}

export type ListAttendanceQuery = {
  date?: string
  driver_id?: string
  period?: AttendancePeriod
  status?: AttendanceStatus
  page?: number
  per_page?: number
}

export type AdjustAttendanceBody = {
  driver_id: string
  work_date: string
  checked_in_at: string
  checked_out_at?: string | null
  reason: string
}

export function listAttendance(query: ListAttendanceQuery, signal?: AbortSignal) {
  return api.get<AttendancePage>('/attendance', {
    query: toQuery({ ...query, per_page: query.per_page ?? PAGE_SIZE }),
    signal,
  })
}

export function attendanceSummary(signal?: AbortSignal) {
  return api.get<{ data: AttendanceSummary }>('/attendance/today/summary', { signal })
}

export function driverAttendance(
  driverId: string,
  query: ListAttendanceQuery,
  signal?: AbortSignal,
) {
  return api.get<AttendancePage>(`/drivers/${driverId}/attendance`, {
    query: toQuery(query),
    signal,
  })
}

export function attendanceQr(signal?: AbortSignal) {
  return api.get<AttendanceQr>('/attendance/qr', { signal })
}

export function adjustAttendance(body: AdjustAttendanceBody) {
  return api.post('/attendance/adjust', body)
}
