import { api } from './client'
import { toQuery } from './to-query'
import type { Paginated, Place } from './types'

export type ListPlacesQuery = {
  search?: string
  is_active?: boolean
  is_headquarters?: boolean
  page?: number
  per_page?: number
}

export type CreatePlaceBody = {
  name_en: string
  name_ar: string
  latitude?: number
  longitude?: number
  address?: string
  is_headquarters?: boolean
  is_active?: boolean
}

export type UpdatePlaceBody = {
  name_en?: string
  name_ar?: string
  latitude?: number | null
  longitude?: number | null
  address?: string | null
  is_headquarters?: boolean
  is_active?: boolean
}

export function listPlaces(query: ListPlacesQuery, signal?: AbortSignal) {
  return api.get<Paginated<Place>>('/places', { query: toQuery(query), signal })
}

export function createPlace(body: CreatePlaceBody) {
  return api.post<Place>('/places', body)
}

export function updatePlace(id: string, body: UpdatePlaceBody) {
  return api.patch<Place>(`/places/${id}`, body)
}

export function deletePlace(id: string) {
  return api.delete<Place>(`/places/${id}`)
}

export async function listActivePlaces(signal?: AbortSignal): Promise<Place[]> {
  const collected: Place[] = []
  for (let page = 1; page <= 10; page += 1) {
    const response = await listPlaces({ is_active: true, page, per_page: 100 }, signal)
    collected.push(...response.data)
    if (page >= response.meta.last_page) break
  }
  return collected
}
