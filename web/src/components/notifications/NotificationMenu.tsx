import { useEffect, useId, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, useNavigate } from 'react-router-dom'
import {
  useMarkNotificationRead,
  useNotifications,
  useUnreadNotificationCount,
} from '../../api/use-notifications'
import { useAuth } from '../../auth/auth-context'
import { isWebRole } from '../../auth/roles'
import { formatWhen } from '../../lib/format'
import { notificationHref, notificationValues } from '../../lib/notification-links'

export function NotificationMenu() {
  const { t, i18n } = useTranslation()
  const { user } = useAuth()
  const navigate = useNavigate()
  const [open, setOpen] = useState(false)
  const menuId = useId()
  const rootRef = useRef<HTMLDivElement>(null)
  const unread = useUnreadNotificationCount()
  const list = useNotifications({ per_page: 10 }, open)
  const markRead = useMarkNotificationRead()
  const count = unread.data?.count ?? 0
  const role = user && isWebRole(user.role) ? user.role : null

  useEffect(() => {
    function onPointer(event: MouseEvent) {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false)
    }
    function onKey(event: KeyboardEvent) {
      if (event.key === 'Escape') setOpen(false)
    }
    document.addEventListener('mousedown', onPointer)
    document.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onPointer)
      document.removeEventListener('keydown', onKey)
    }
  }, [])

  async function openItem(id: string, href: string | null) {
    setOpen(false)
    try {
      await markRead.mutateAsync(id)
    } catch {
      // The row stays unread until the next poll if the mark fails.
    }
    if (href) navigate(href)
  }

  return (
    <div ref={rootRef} className="relative">
      <button
        type="button"
        className="relative inline-flex h-10 w-10 items-center justify-center rounded-control border-[1.5px] border-mid text-deep"
        aria-label={t('notifications.title')}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={menuId}
        onClick={() => setOpen((current) => !current)}
      >
        <span aria-hidden="true">🔔</span>
        {count > 0 ? (
          <span className="absolute -end-1 -top-1 inline-flex min-w-5 items-center justify-center rounded-full bg-danger px-1 text-[10px] font-bold text-white">
            {count > 99 ? '99+' : count}
          </span>
        ) : null}
      </button>
      {open ? (
        <div
          id={menuId}
          role="menu"
          className="absolute end-0 z-20 mt-1 w-80 max-w-[85vw] rounded-control border border-pale bg-white py-1 shadow-dialog"
        >
          <div className="max-h-96 overflow-y-auto">
            {list.isPending ? (
              <p className="px-3 py-3 text-sm text-navy/70">{t('common.loading')}</p>
            ) : list.isError ? (
              <p role="alert" className="px-3 py-3 text-sm text-danger">
                {t('common.error')}
              </p>
            ) : (list.data?.data.length ?? 0) === 0 ? (
              <p className="px-3 py-3 text-sm text-navy/70">{t('notifications.empty')}</p>
            ) : (
              list.data?.data.map((item) => {
                const values = notificationValues(item.params, i18n.language)
                const href = role ? notificationHref(role, item) : null
                return (
                  <button
                    key={item.id}
                    type="button"
                    role="menuitem"
                    className={`block w-full px-3 py-2 text-start hover:bg-pale ${
                      item.read_at ? 'bg-white' : 'bg-pale'
                    }`}
                    onClick={() => {
                      void openItem(item.id, href)
                    }}
                  >
                    <span className="block text-sm font-bold text-navy">
                      {t(item.title_key, values)}
                    </span>
                    <span className="mt-0.5 block text-sm text-navy/80">
                      {t(item.body_key, values)}
                    </span>
                    <span className="mt-1 block text-xs text-navy/60">
                      {formatWhen(item.created_at, i18n.language)}
                    </span>
                  </button>
                )
              })
            )}
          </div>
          <Link
            to="/notifications"
            role="menuitem"
            className="block border-t border-pale px-3 py-2 text-sm font-bold text-deep hover:bg-pale"
            onClick={() => setOpen(false)}
          >
            {t('notifications.viewAll')}
          </Link>
        </div>
      ) : null}
    </div>
  )
}
