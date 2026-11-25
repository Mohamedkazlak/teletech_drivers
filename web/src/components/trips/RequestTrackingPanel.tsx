import { useTranslation } from 'react-i18next'
import type { RequestTracking, RequestTrackingEvent, RequestTrackingStage } from '../../api/types'
import { formatWhen } from '../../lib/format'
import { localizedName } from '../../lib/names'

type RequestTrackingPanelProps = {
  tracking: RequestTracking
}

export function RequestTrackingPanel({ tracking }: RequestTrackingPanelProps) {
  const { t, i18n } = useTranslation()
  const reason = tracking.rejection_reason?.trim()
  const approved = eventFor(tracking, 'approved')
  const assigned = eventFor(tracking, 'driver_assigned')
  const current = eventFor(tracking, tracking.stage)

  return (
    <section aria-label={t('tracking.nowQuestion')} className="flex flex-col gap-3">
      {tracking.stage === 'rejected' ? (
        <div className="rounded-control bg-danger/14 px-3 py-3 text-danger">
          <p className="text-sm font-semibold">{t('tracking.rejectionTitle')}</p>
          {reason ? <p className="mt-1 text-base text-navy">{reason}</p> : null}
        </div>
      ) : null}
      <Answer question={t('tracking.approvedQuestion')} answer={approvedAnswer(tracking, approved, t, i18n.language)} />
      <Answer
        question={t('tracking.driverQuestion')}
        answer={driverAnswer(tracking, assigned, t, i18n.language)}
      />
      <Answer
        question={t('tracking.nowQuestion')}
        answer={withTime(t(`tracking.${tracking.stage}`), current?.reached_at, i18n.language)}
      />
      {tracking.scheduled_at ? (
        <p className="text-sm text-navy">
          {t('tracking.scheduled', { time: formatWhen(tracking.scheduled_at, i18n.language) })}
        </p>
      ) : null}
      {tracking.vehicle ? (
        <p className="text-sm text-navy">
          {t('tracking.vehicle', { license: tracking.vehicle.car_license })}
        </p>
      ) : null}
      <ol className="flex flex-col gap-3">
        {tracking.timeline.map((event, index) => (
          <li key={`${event.stage}-${index}`} className="flex gap-3">
            <span
              aria-hidden
              className={`mt-1 size-3 shrink-0 rounded-full ${event.reached_at ? 'bg-success' : 'bg-pale'}`}
            />
            <div>
              <p className={`text-sm font-semibold ${event.reached_at ? 'text-navy' : 'text-navy/45'}`}>
                {t(`tracking.${event.stage}`)}
              </p>
              {event.reached_at ? (
                <p className="text-sm text-ink-muted">{formatWhen(event.reached_at, i18n.language)}</p>
              ) : null}
              {event.actor_role ? (
                <p className="text-sm text-ink-muted">{t(`role.${event.actor_role}`)}</p>
              ) : null}
            </div>
          </li>
        ))}
      </ol>
    </section>
  )
}

function Answer({ question, answer }: { question: string; answer: string }) {
  return (
    <div>
      <p className="text-sm font-semibold text-navy">{question}</p>
      <p className="text-base text-navy">{answer}</p>
    </div>
  )
}

function eventFor(tracking: RequestTracking, stage: RequestTrackingStage): RequestTrackingEvent | undefined {
  return tracking.timeline.find((event) => event.stage === stage)
}

function approvedAnswer(
  tracking: RequestTracking,
  approved: RequestTrackingEvent | undefined,
  t: (key: string, options?: Record<string, string>) => string,
  language: string,
): string {
  if (tracking.stage === 'rejected') return t('tracking.rejected')
  if (approved?.reached_at) {
    return t('tracking.approvedAt', { time: formatWhen(approved.reached_at, language) })
  }
  return t('tracking.pendingApproval')
}

function driverAnswer(
  tracking: RequestTracking,
  assigned: RequestTrackingEvent | undefined,
  t: (key: string, options?: Record<string, string>) => string,
  language: string,
): string {
  const driver = tracking.driver
  if (!driver) return t('tracking.notYet')
  const name = localizedName(language, driver.name_en, driver.name_ar) || t('tracking.notYet')
  const phone = driver.phone?.trim() ? driver.phone : t('tracking.noPhone')
  const contact = t('tracking.driverLine', { name, phone })
  if (!assigned?.reached_at) return contact
  return withTime(contact, assigned.reached_at, language)
}

function withTime(label: string, reachedAt: string | null | undefined, language: string): string {
  if (!reachedAt) return label
  return `${label} · ${formatWhen(reachedAt, language)}`
}
