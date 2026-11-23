import { createContext, useContext } from 'react'
import type { User } from '../api/types'

export type AuthStatus = 'loading' | 'anonymous' | 'authenticated' | 'error'

export type LoginResult =
  | { ok: true; user: User }
  | { ok: false; reason: 'mobile-only' }
  | { ok: false; reason: 'error'; message: string; status: number }

export type AuthContextValue = {
  status: AuthStatus
  user: User | null
  login: (email: string, password: string) => Promise<LoginResult>
  logout: () => Promise<void>
  refresh: () => Promise<User | null>
}

export const AuthContext = createContext<AuthContextValue | null>(null)

export function useAuth(): AuthContextValue {
  const value = useContext(AuthContext)
  if (!value) throw new Error('useAuth must be used within AuthProvider')
  return value
}
