import { api } from './client'
import { toQuery } from './to-query'
import type { DataEnvelope, LiveMapDriver } from './types'
import type { AttendanceListFilter } from './drivers'

export type LiveMapQuery = {
  driver_id?: string
  attendance?: AttendanceListFilter
}

export function listLiveMap(query: LiveMapQuery, signal?: AbortSignal) {
  return api.get<DataEnvelope<LiveMapDriver>>('/live-map', { query: toQuery(query), signal })
}
