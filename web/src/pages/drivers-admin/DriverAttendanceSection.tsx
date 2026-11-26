import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { AttendancePeriod } from '../../api/attendance'
import { useDriverAttendance } from '../../api/use-attendance'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { messageForApiError } from '../../lib/api-message'

const periods: AttendancePeriod[] = ['week', 'month', 'year']

export function DriverAttendanceSection({ driverId }: { driverId: string }) {
  const { t } = useTranslation()
  const [period, setPeriod] = useState<AttendancePeriod>('week')
  const history = useDriverAttendance(driverId, { period })
  const totals = history.data?.totals

  return (
    <section className="rounded-card border border-line bg-white p-4">
      <h2 className="text-lg font-semibold text-navy">{t('nav.attendance')}</h2>
      <div className="mt-3 flex gap-2">
        {periods.map((item) => (
          <button
            key={item}
            type="button"
            className={item === period ? 'font-semibold text-deep' : 'text-ink-muted'}
            onClick={() => setPeriod(item)}
          >
            {t(`period.${item}`)}
          </button>
        ))}
      </div>
      {history.isPending ? <p>{t('common.loading')}</p> : null}
      {history.isError ? <p className="text-danger-ink">{messageForApiError(history.error, t)}</p> : null}
      {totals ? (
        <p className="mt-3 text-sm text-navy">
          {t('attendance.totals', {
            present: totals.days_present,
            absent: totals.days_absent,
            hours: totals.total_on_site_hours,
          })}
        </p>
      ) : null}
      <ul className="mt-3 flex flex-col gap-2">
        {(history.data?.data ?? []).map((day) => (
          <li key={day.work_date} className="flex items-center justify-between gap-3 text-sm">
            <span>{day.work_date}</span>
            <StatusBadge status={day.status} />
          </li>
        ))}
      </ul>
    </section>
  )
}
