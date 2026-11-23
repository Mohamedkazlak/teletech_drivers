import { useEffect, useMemo, useState } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import Echo from 'laravel-echo'
import Pusher from 'pusher-js'
import { api } from '../api/client'
import type { WebRole } from '../api/types'
import { resolveReverbConfig } from './config'
import { REALTIME_EVENTS, applyRealtimeEvent, type RealtimePayload } from './events'

export type RealtimeStatus = 'connecting' | 'connected' | 'disconnected'

type BroadcastAuth = {
  auth: string
}

type PusherConnection = {
  bind: (event: string, callback: (state: { current: string }) => void) => void
}

function currentPage(): { protocol: string; hostname: string } {
  if (typeof window === 'undefined') {
    return { protocol: 'http:', hostname: '127.0.0.1' }
  }
  return { protocol: window.location.protocol, hostname: window.location.hostname }
}

function roleChannel(role: WebRole): string {
  if (role === 'admin') return 'role.admin'
  if (role === 'company_admin') return 'role.company-admin'
  return 'role.drivers-admin'
}

function toStatus(state: string): RealtimeStatus {
  if (state === 'connected') return 'connected'
  if (state === 'connecting' || state === 'initialized') return 'connecting'
  return 'disconnected'
}

/**
 * Subscribes to this role's private channel and refreshes the matching queries.
 * Observer: Echo connection. Falls back to polling when the socket is down.
 */
export function useFleetRealtime(role: WebRole | null): RealtimeStatus {
  const queryClient = useQueryClient()
  const config = useMemo(
    () => (role ? resolveReverbConfig(import.meta.env, currentPage()) : null),
    [role],
  )
  const [status, setStatus] = useState<RealtimeStatus>('connecting')

  useEffect(() => {
    if (!role || !config) return

    window.Pusher = Pusher
    const echo = new Echo({
      broadcaster: 'reverb',
      key: config.key,
      wsHost: config.host,
      wsPort: config.port,
      wssPort: config.port,
      forceTLS: config.scheme === 'https',
      enabledTransports: ['ws', 'wss'],
      authorizer: (channel) => ({
        authorize: (socketId, callback) => {
          void api
            .post<BroadcastAuth>('/broadcasting/auth', {
              socket_id: socketId,
              channel_name: channel.name,
            })
            .then((data) => callback(null, data))
            .catch((error: unknown) => {
              callback(error instanceof Error ? error : new Error('Unauthorized'), null)
            })
        },
      }),
    })

    const connection = (echo.connector as { pusher?: { connection?: PusherConnection } }).pusher
      ?.connection
    const onState = (state: { current: string }) => setStatus(toStatus(state.current))
    connection?.bind('state_change', onState)

    const subscription = echo.private(roleChannel(role))
    for (const eventName of REALTIME_EVENTS) {
      subscription.listen(`.${eventName}`, (payload: RealtimePayload) => {
        applyRealtimeEvent(queryClient, eventName, payload ?? {})
      })
    }

    return () => {
      echo.disconnect()
    }
  }, [config, queryClient, role])

  if (!role || !config) return 'disconnected'
  return status
}
