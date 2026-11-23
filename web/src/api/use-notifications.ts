import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useNotificationPoll } from '../lib/use-notification-poll'
import { retryTransient } from './retry'
import {
  listNotifications,
  markAllNotificationsRead,
  markNotificationRead,
  unreadNotificationCount,
  type NotificationListQuery,
} from './notifications'

export const notificationKeys = {
  all: ['notifications'] as const,
  list: (query: NotificationListQuery) => ['notifications', 'list', query] as const,
  unread: ['notifications', 'unread-count'] as const,
}

export function useUnreadNotificationCount() {
  const pollMs = useNotificationPoll()
  return useQuery({
    queryKey: notificationKeys.unread,
    queryFn: ({ signal }) => unreadNotificationCount(signal),
    refetchInterval: pollMs,
    refetchIntervalInBackground: false,
    retry: retryTransient,
  })
}

export function useNotifications(query: NotificationListQuery, enabled = true) {
  const pollMs = useNotificationPoll()
  return useQuery({
    queryKey: notificationKeys.list(query),
    queryFn: ({ signal }) => listNotifications(query, signal),
    enabled,
    refetchInterval: enabled ? pollMs : false,
    refetchIntervalInBackground: false,
    retry: retryTransient,
  })
}

export function useMarkNotificationRead() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => markNotificationRead(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: notificationKeys.all })
    },
  })
}

export function useMarkAllNotificationsRead() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: () => markAllNotificationsRead(),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: notificationKeys.all })
    },
  })
}
