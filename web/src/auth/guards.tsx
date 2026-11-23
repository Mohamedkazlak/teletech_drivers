import type { ReactNode } from 'react'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import type { WebRole } from '../api/types'
import { BrandMark } from '../components/brand/BrandMark'
import { primaryButtonClass } from '../components/ui/styles'
import { useAuth } from './auth-context'
import { homePath, isWebRole } from './roles'

export function LoadingScreen() {
  const { t } = useTranslation()
  return (
    <div className="grid min-h-dvh place-items-center bg-scaffold text-navy">
      <div className="flex flex-col items-center gap-4">
        <BrandMark className="h-12 w-auto" />
        <p role="status">{t('common.loading')}</p>
      </div>
    </div>
  )
}

export function RequireAuth({
  children,
  allowPasswordChange = false,
}: {
  children: ReactNode
  allowPasswordChange?: boolean
}) {
  const { status, user, refresh } = useAuth()
  const location = useLocation()
  const { t } = useTranslation()

  if (status === 'loading') return <LoadingScreen />
  if (status === 'error') {
    return (
      <div className="grid min-h-dvh place-items-center bg-scaffold px-4">
        <div className="w-full max-w-md rounded-card bg-white p-6 shadow-dialog">
          <BrandMark className="mb-4 h-10 w-auto" />
          <p className="text-navy">{t('common.sessionError')}</p>
          <button
            type="button"
            className={`${primaryButtonClass} mt-4`}
            onClick={() => {
              void refresh()
            }}
          >
            {t('common.retry')}
          </button>
        </div>
      </div>
    )
  }
  if (!user || !isWebRole(user.role)) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }
  if (user.must_change_password && !allowPasswordChange) {
    return <Navigate to="/change-password" replace />
  }
  return children
}

export function RequireRole({ role, children }: { role: WebRole; children: ReactNode }) {
  const { user } = useAuth()
  if (!user || !isWebRole(user.role)) return <Navigate to="/login" replace />
  if (user.role !== role) return <Navigate to={homePath(user.role)} replace />
  return children
}

export function RoleLayout({ role }: { role: WebRole }) {
  return (
    <RequireRole role={role}>
      <Outlet />
    </RequireRole>
  )
}

export function GuestOnly({ children }: { children: ReactNode }) {
  const { status, user } = useAuth()
  if (status === 'loading') return <LoadingScreen />
  if (user && isWebRole(user.role)) {
    if (user.must_change_password) return <Navigate to="/change-password" replace />
    return <Navigate to={homePath(user.role)} replace />
  }
  return children
}

export function HomeRedirect() {
  const { status, user } = useAuth()
  if (status === 'loading') return <LoadingScreen />
  if (!user || !isWebRole(user.role)) return <Navigate to="/login" replace />
  if (user.must_change_password) return <Navigate to="/change-password" replace />
  return <Navigate to={homePath(user.role)} replace />
}
