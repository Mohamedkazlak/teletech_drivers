import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useCallback, useMemo, useSyncExternalStore, type ReactNode } from 'react'
import { api } from '../api/client'
import { ApiError } from '../api/errors'
import { sessionStore } from '../api/session'
import type { AuthTokenResponse, User } from '../api/types'
import { AuthContext, type AuthContextValue, type LoginResult } from './auth-context'
import { isWebRole } from './roles'

const ME_KEY = ['auth', 'me'] as const

export function AuthProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient()
  const token = useSyncExternalStore(sessionStore.subscribe, sessionStore.get, () => null)

  const meQuery = useQuery({
    queryKey: ME_KEY,
    enabled: token !== null,
    retry: false,
    staleTime: 30_000,
    queryFn: async () => {
      try {
        const user = await api.get<User>('/auth/me', { skipAuthRedirect: true })
        if (!isWebRole(user.role)) {
          sessionStore.clear()
          throw new ApiError('This account cannot use the web console.', 403)
        }
        return user
      } catch (error) {
        if (error instanceof ApiError && error.status === 401) {
          sessionStore.clear()
        }
        throw error
      }
    },
  })

  const user = token && meQuery.data && isWebRole(meQuery.data.role) ? meQuery.data : null
  const status: AuthContextValue['status'] =
    token === null ? 'anonymous' : user ? 'authenticated' : meQuery.isError ? 'error' : 'loading'

  const login = useCallback(
    async (email: string, password: string): Promise<LoginResult> => {
      try {
        const body = await api.post<AuthTokenResponse>(
          '/auth/login',
          { email, password },
          { skipAuthRedirect: true },
        )
        if (!isWebRole(body.user.role)) {
          try {
            await api.post('/auth/logout', undefined, {
              token: body.token,
              skipAuthRedirect: true,
            })
          } catch {
            // The token is discarded either way.
          }
          return { ok: false, reason: 'mobile-only' }
        }
        queryClient.setQueryData(ME_KEY, body.user)
        sessionStore.set(body.token)
        return { ok: true, user: body.user }
      } catch (error) {
        if (error instanceof ApiError) {
          return { ok: false, reason: 'error', message: error.message, status: error.status }
        }
        return { ok: false, reason: 'error', message: 'Request failed.', status: 0 }
      }
    },
    [queryClient],
  )

  const logout = useCallback(async () => {
    try {
      await api.post('/auth/logout', undefined, { skipAuthRedirect: true })
    } catch {
      // Local session still ends.
    }
    sessionStore.clear()
    queryClient.removeQueries({ queryKey: ME_KEY })
  }, [queryClient])

  const refresh = useCallback(async () => {
    const next = await api.get<User>('/auth/me')
    queryClient.setQueryData(ME_KEY, next)
    return next
  }, [queryClient])

  const value = useMemo<AuthContextValue>(
    () => ({ status, user, login, logout, refresh }),
    [status, user, login, logout, refresh],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
