import { useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../../auth/auth-context'
import { isWebRole } from '../../auth/roles'
import { useDialogKey } from '../ui/use-dialog'
import { useFleetRealtime } from '../../realtime/use-fleet-realtime'
import { Sidebar } from './Sidebar'
import { TopBar } from './TopBar'

export function AppShell() {
  const { t } = useTranslation()
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const connection = useFleetRealtime(user && isWebRole(user.role) ? user.role : null)
  const [menuPath, setMenuPath] = useState<string | null>(null)
  const open = menuPath === location.pathname
  const menuRef = useDialogKey(open, () => setMenuPath(null))
  // The page rises in once when the console opens; route changes only cross-fade.
  // Filter changes (same path) don't animate.
  const [firstPath] = useState(location.pathname)

  if (!user || !isWebRole(user.role)) return null

  async function signOut() {
    await logout()
    navigate('/login', { replace: true })
  }

  return (
    <div className="min-h-dvh bg-scaffold text-navy">
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:absolute focus:start-3 focus:top-3 focus:z-50 focus:rounded-control focus:bg-white focus:px-3 focus:py-2 focus:text-navy focus:shadow-float"
      >
        {t('common.skip')}
      </a>
      <div className="fixed inset-y-0 start-0 z-20 hidden w-64 lg:block">
        <Sidebar role={user.role} />
      </div>
      {open ? (
        <div className="lg:hidden">
          <button
            type="button"
            className="fixed inset-0 z-30 bg-navy-deep/45 backdrop-blur-[2px] animate-fade"
            aria-label={t('common.close')}
            onClick={() => setMenuPath(null)}
          />
          <div
            ref={menuRef}
            role="dialog"
            aria-modal="true"
            aria-label={t('common.menu')}
            className="fixed inset-y-0 start-0 z-40 w-72 max-w-[85vw] shadow-dialog drawer-panel"
          >
            <Sidebar role={user.role} onNavigate={() => setMenuPath(null)} />
          </div>
        </div>
      ) : null}
      <div className="lg:ps-64">
        <TopBar
          user={user}
          connection={connection}
          onMenu={() => setMenuPath(location.pathname)}
          onLogout={() => {
            void signOut()
          }}
        />
        <main
          id="main"
          className={`mx-auto w-full max-w-[1400px] px-4 py-6 sm:px-6 lg:px-8 animate-rise`}
        >
          <div
            key={location.pathname}
            className={firstPath === location.pathname ? undefined : 'animate-fade-quick'}
          >
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  )
}

export function PageHeading({ title, children }: { title: string; children?: ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
      <h1 className="text-[26px] leading-tight font-semibold tracking-[-0.02em] text-balance text-navy">
        {title}
      </h1>
      {children}
    </div>
  )
}
