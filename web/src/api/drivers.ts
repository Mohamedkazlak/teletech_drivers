import { resolveApiBaseUrl } from './base-url'
import { api } from './client'
import { ApiError, normalizeApiError } from './errors'
import { sessionStore } from './session'
import { PAGE_SIZE, toQuery } from './to-query'
import type { Driver, DriverCompletedTrip, DriverStats, FleetPeriod, Paginated } from './types'

export type AttendanceListFilter = 'checked_in' | 'not_checked_in'

export type ListDriversQuery = {
  is_active?: boolean
  attendance?: AttendanceListFilter
  search?: string
  include_deleted?: boolean
  page?: number
  per_page?: number
}

export type DriverStatsQuery = {
  period: FleetPeriod
  date?: string
}

export type ListDriverTripsQuery = DriverStatsQuery & {
  page?: number
  per_page?: number
}

export type CreateDriverBody = {
  name_en: string
  name_ar: string
  email: string
  password: string
  phone: string | null
  national_id: string
  car_license: string
  personal_license: string
  favorite_place_ids: string[]
}

export type UpdateDriverBody = {
  name_en?: string
  name_ar?: string
  phone?: string | null
  national_id?: string
  car_license?: string
  personal_license?: string
  favorite_place_ids?: string[]
  is_active?: boolean
  password?: string
}

export type DriverListFilters = {
  attendance: '' | AttendanceListFilter
  search: string
  page: number
  includeDeleted?: boolean
}

export function driversListQuery(input: DriverListFilters): ListDriversQuery {
  return {
    attendance: input.attendance || undefined,
    search: input.search || undefined,
    include_deleted: input.includeDeleted ? true : undefined,
    page: input.page > 1 ? input.page : undefined,
    per_page: PAGE_SIZE,
  }
}

export function driverActivityQuery(period: FleetPeriod, date?: string): DriverStatsQuery {
  if (period === 'all') return { period }
  return { period, date }
}

export function listDrivers(query: ListDriversQuery, signal?: AbortSignal) {
  return api.get<Paginated<Driver>>('/drivers', { query: toQuery(query), signal })
}

export function getDriver(id: string, signal?: AbortSignal) {
  return api.get<Driver>(`/drivers/${id}`, { signal })
}

export function getDriverStats(id: string, query: DriverStatsQuery, signal?: AbortSignal) {
  return api.get<DriverStats>(`/drivers/${id}/stats`, { query: toQuery(query), signal })
}

export function listDriverTrips(id: string, query: ListDriverTripsQuery, signal?: AbortSignal) {
  return api.get<Paginated<DriverCompletedTrip>>(`/drivers/${id}/trips`, {
    query: toQuery(query),
    signal,
  })
}

export function createDriver(body: CreateDriverBody) {
  return api.post<Driver>('/drivers', body)
}

export function updateDriver(id: string, body: UpdateDriverBody) {
  return api.patch<Driver>(`/drivers/${id}`, body)
}

export function deleteDriver(id: string) {
  return api.delete<Driver>(`/drivers/${id}`)
}

export function restoreDriver(id: string) {
  return api.post<Driver>(`/drivers/${id}/restore`)
}

export type DriverReportPeriod = 'week' | 'month' | 'year'

export type DriverReportDownload = {
  driverId: string
  period: DriverReportPeriod
  date: string
  project?: string
}

export async function downloadDriverReport(input: DriverReportDownload): Promise<void> {
  const params = new URLSearchParams({
    period: input.period,
    date: input.date,
  })
  const project = input.project?.trim() ?? ''
  if (project !== '') params.set('project', project)

  const page =
    typeof window === 'undefined'
      ? { protocol: 'http:', hostname: '127.0.0.1' }
      : { protocol: window.location.protocol, hostname: window.location.hostname }
  const token = sessionStore.get()
  const headers = new Headers({ Accept: 'application/pdf' })
  if (token) headers.set('Authorization', `Bearer ${token}`)

  let response: Response
  try {
    response = await fetch(
      `${resolveApiBaseUrl(import.meta.env.VITE_API_BASE_URL, page)}/drivers/${input.driverId}/report/export?${params.toString()}`,
      { headers },
    )
  } catch {
    throw new ApiError('Network request failed.', 0)
  }

  if (!response.ok) {
    const text = await response.text()
    let body: unknown = null
    if (text) {
      try {
        body = JSON.parse(text) as unknown
      } catch {
        body = { message: text }
      }
    }
    throw normalizeApiError(response.status, body)
  }

  const blob = await response.blob()
  const fallback = `driver-report-${input.driverId}-${input.period}-${input.date}.pdf`
  const named = filenameFrom(response.headers.get('Content-Disposition'), fallback)
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = named
  document.body.appendChild(link)
  link.click()
  link.remove()
  URL.revokeObjectURL(url)
}

function filenameFrom(header: string | null, fallback: string): string {
  if (!header) return fallback
  const match = /filename="([^"]+)"/.exec(header)
  return match?.[1] || fallback
}

export async function listAllDrivers(signal?: AbortSignal): Promise<Driver[]> {
  const collected: Driver[] = []
  for (let page = 1; page <= 10; page += 1) {
    const response = await listDrivers({ page, per_page: 100 }, signal)
    collected.push(...response.data)
    if (page >= response.meta.last_page) break
  }
  return collected
}
