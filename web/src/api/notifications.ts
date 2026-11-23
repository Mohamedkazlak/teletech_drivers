import { api } from './client'
import type { Paginated } from './types'

export type AppNotification = {
  id: string
  type: string
  title_key: string
  body_key: string
  params: Record<string, string>
  trip_request_id: string | null
  trip_id: string | null
  read_at: string | null
  created_at: string
}

export type NotificationListQuery = {
  page?: number
  per_page?: number
  unread?: boolean
}

function asParams(value: unknown): Record<string, string> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) return {}
  const params: Record<string, string> = {}
  for (const [key, item] of Object.entries(value)) {
    if (item === null || item === undefined) continue
    const text = String(item).trim()
    if (text !== '') params[key] = text
  }
  return params
}

export function parseNotification(value: unknown): AppNotification {
  const row = value as Record<string, unknown>
  return {
    id: String(row.id ?? ''),
    type: String(row.type ?? ''),
    title_key: String(row.title_key ?? ''),
    body_key: String(row.body_key ?? ''),
    params: asParams(row.params),
    trip_request_id: typeof row.trip_request_id === 'string' ? row.trip_request_id : null,
    trip_id: typeof row.trip_id === 'string' ? row.trip_id : null,
    read_at: typeof row.read_at === 'string' ? row.read_at : null,
    created_at: String(row.created_at ?? ''),
  }
}

export function listNotifications(query: NotificationListQuery, signal?: AbortSignal) {
  return api
    .get<Paginated<unknown>>('/notifications', { query, signal })
    .then((page) => ({
      ...page,
      data: page.data.map(parseNotification),
    }))
}

export function unreadNotificationCount(signal?: AbortSignal) {
  return api.get<{ count: number }>('/notifications/unread-count', { signal })
}

export function markNotificationRead(id: string) {
  return api.post<unknown>(`/notifications/${id}/read`).then(parseNotification)
}

export function markAllNotificationsRead() {
  return api.post<{ updated: number }>('/notifications/read-all')
}
