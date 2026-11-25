import type { TFunction } from 'i18next'
import { useId, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { downloadDriverReport, type DriverReportPeriod } from '../../api/drivers'
import { FormField } from '../../components/ui/FormField'
import { alertClass, controlClass, primaryButtonClass, secondaryButtonClass } from '../../components/ui/styles'
import { useDialogKey } from '../../components/ui/use-dialog'
import { messageForApiError } from '../../lib/api-message'
import { formatDateParam } from '../../lib/period'

type ExportReportDialogProps = {
  open: boolean
  driverId: string
  driverName: string
  onClose: () => void
}

export function ExportReportDialog({
  open,
  driverId,
  driverName,
  onClose,
}: ExportReportDialogProps) {
  const { t } = useTranslation()
  const titleId = useId()
  const periodId = useId()
  const dateId = useId()
  const projectId = useId()
  const dialogRef = useDialogKey(open, onClose)
  const [period, setPeriod] = useState<DriverReportPeriod>('month')
  const [date, setDate] = useState(() => formatDateParam(new Date()))
  const [project, setProject] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (!open) return null

  async function onDownload() {
    setBusy(true)
    setError(null)
    try {
      await downloadDriverReport({
        driverId,
        period,
        date: anchorDate(period, date),
        project,
      })
      onClose()
    } catch (caught) {
      setError(messageForApiError(caught, t))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <button
        type="button"
        className="absolute inset-0 bg-navy-deep/45 backdrop-blur-[2px] animate-fade"
        aria-label={t('common.cancel')}
        onClick={onClose}
      />
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="relative w-full max-w-md rounded-[20px] bg-white p-6 shadow-dialog animate-pop"
      >
        <h2 id={titleId} className="text-lg font-semibold text-navy">
          {t('driverAdmin.exportTitle')}
        </h2>
        <p className="mt-2 text-sm text-ink-muted">{driverName}</p>
        <div className="mt-4 flex flex-col gap-3">
          <FormField id={periodId} label={t('driverAdmin.exportPeriod')}>
            <select
              id={periodId}
              className={controlClass}
              value={period}
              disabled={busy}
              onChange={(event) => setPeriod(event.target.value as DriverReportPeriod)}
            >
              <option value="week">{t('period.week')}</option>
              <option value="month">{t('period.month')}</option>
              <option value="year">{t('period.year')}</option>
            </select>
          </FormField>
          <FormField id={dateId} label={dateLabel(period, t)}>
            {period === 'year' ? (
              <input
                id={dateId}
                className={controlClass}
                type="number"
                inputMode="numeric"
                min={2000}
                max={2100}
                value={date.slice(0, 4)}
                disabled={busy}
                onChange={(event) => {
                  const year = event.target.value.padStart(4, '0').slice(0, 4)
                  setDate(`${year}-01-01`)
                }}
              />
            ) : (
              <input
                id={dateId}
                className={controlClass}
                type={period === 'month' ? 'month' : 'date'}
                value={period === 'month' ? date.slice(0, 7) : date}
                disabled={busy}
                onChange={(event) =>
                  setDate(period === 'month' ? `${event.target.value}-01` : event.target.value)
                }
              />
            )}
          </FormField>
          <FormField id={projectId} label={t('driverAdmin.exportProject')} hint={t('driverAdmin.exportProjectHint')}>
            <input
              id={projectId}
              className={controlClass}
              type="text"
              maxLength={200}
              value={project}
              disabled={busy}
              onChange={(event) => setProject(event.target.value)}
            />
          </FormField>
          {error ? <p className={alertClass}>{error}</p> : null}
          {busy ? (
            <p role="status" className="text-sm text-ink-muted">
              {t('driverAdmin.exportDownloading')}
            </p>
          ) : null}
        </div>
        <div className="mt-5 flex justify-end gap-2">
          <button type="button" className={secondaryButtonClass} onClick={onClose} disabled={busy}>
            {t('common.cancel')}
          </button>
          <button type="button" className={primaryButtonClass} disabled={busy} onClick={() => void onDownload()}>
            {t('driverAdmin.exportDownload')}
          </button>
        </div>
      </div>
    </div>
  )
}

function dateLabel(period: DriverReportPeriod, t: TFunction): string {
  if (period === 'month') return t('driverAdmin.exportMonth')
  if (period === 'year') return t('driverAdmin.exportYear')
  return t('driverAdmin.exportDate')
}

function anchorDate(period: DriverReportPeriod, date: string): string {
  if (period === 'month') return `${date.slice(0, 7)}-01`
  if (period === 'year') return `${date.slice(0, 4)}-01-01`
  return date
}
