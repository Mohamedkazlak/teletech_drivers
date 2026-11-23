import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'
import type { AppNotification } from '../api/notifications'
import {
  useMarkAllNotificationsRead,
  useMarkNotificationRead,
  useNotifications,
} from '../api/use-notifications'
import { useAuth } from '../auth/auth-context'
import { isWebRole } from '../auth/roles'
import { PageHeading } from '../components/layout/AppShell'
import { secondaryButtonClass } from '../components/ui/styles'
import { messageForApiError } from '../lib/api-message'
import { formatWhen } from '../lib/format'
import { notificationHref, notificationValues } from '../lib/notification-links'
import { useListParams } from '../lib/use-list-params'

export function NotificationsPage() {
  const { t, i18n } = useTranslation()
  const { user } = useAuth()
  const navigate = useNavigate()
  const { page, setPage } = useListParams()
  const list = useNotifications({ page, per_page: 15 })
  const markRead = useMarkNotificationRead()
  const markAll = useMarkAllNotificationsRead()
  const role = user && isWebRole(user.role) ? user.role : null
  const rows = list.data?.data ?? []
  const hasUnread = rows.some((item) => item.read_at == null)

  async function openItem(item: AppNotification) {
    try {
      await markRead.mutateAsync(item.id)
    } catch {
      return
    }
    if (!role) return
    const href = notificationHref(role, item)
    if (href) navigate(href)
  }

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('notifications.title')}>
        <button
          type="button"
          className={secondaryButtonClass}
          disabled={!hasUnread || markAll.isPending}
          onClick={() => {
            void markAll.mutate()
          }}
        >
          {t('notifications.markAll')}
        </button>
      </PageHeading>
      {list.isPending ? (
        <p role="status" className="text-sm text-navy/70">
          {t('common.loading')}
        </p>
      ) : list.isError ? (
        <div className="flex flex-col items-start gap-3">
          <p role="alert" className="text-sm text-danger">
            {messageForApiError(list.error, t)}
          </p>
          <button type="button" className={secondaryButtonClass} onClick={() => void list.refetch()}>
            {t('common.retry')}
          </button>
        </div>
      ) : rows.length === 0 ? (
        <p className="text-sm text-navy/70">{t('notifications.empty')}</p>
      ) : (
        <ul className="flex flex-col gap-2">
          {rows.map((item) => {
            const values = notificationValues(item.params, i18n.language)
            const unread = item.read_at == null
            return (
              <li key={item.id}>
                <button
                  type="button"
                  className={`w-full rounded-card border px-4 py-3 text-start ${
                    unread ? 'border-deep bg-pale' : 'border-pale bg-white'
                  }`}
                  aria-label={unread ? t('notifications.unread') : undefined}
                  onClick={() => {
                    void openItem(item)
                  }}
                >
                  <span className="block text-sm font-bold text-navy">
                    {t(item.title_key, values)}
                  </span>
                  <span className="mt-1 block text-sm text-navy/80">{t(item.body_key, values)}</span>
                  <span className="mt-1 block text-xs text-navy/60">
                    {formatWhen(item.created_at, i18n.language)}
                  </span>
                </button>
              </li>
            )
          })}
        </ul>
      )}
      {list.data && list.data.meta.last_page > 1 ? (
        <div className="flex items-center justify-between gap-3">
          <button
            type="button"
            className={secondaryButtonClass}
            disabled={page <= 1}
            onClick={() => setPage(page - 1)}
          >
            {t('common.previous')}
          </button>
          <p className="text-sm text-navy/75">
            {t('common.page', { current: page, last: list.data.meta.last_page })}
          </p>
          <button
            type="button"
            className={secondaryButtonClass}
            disabled={page >= list.data.meta.last_page}
            onClick={() => setPage(page + 1)}
          >
            {t('common.next')}
          </button>
        </div>
      ) : null}
    </section>
  )
}
