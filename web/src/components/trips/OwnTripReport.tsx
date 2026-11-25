import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { ApiError } from '../../api/errors'
import type { TripSummary } from '../../api/types'
import { useConfirmTrip } from '../../api/use-trip-requests'
import { useAuth } from '../../auth/auth-context'
import { ownPendingRequestId } from '../../lib/own-trip-report'
import { useToast } from '../ui/toast-context'
import { controlClass, primaryButtonClass, secondaryButtonClass } from '../ui/styles'

const noteLimit = 500

type OwnTripReportProps = {
  trip: TripSummary
}

/** Same report as the employee app: showed up / did not, plus an optional note. */
export function OwnTripReport({ trip }: OwnTripReportProps) {
  const { t } = useTranslation()
  const { user } = useAuth()
  const toast = useToast()
  const confirm = useConfirmTrip()
  const requestId = ownPendingRequestId(trip, user)
  const [showedUp, setShowedUp] = useState<boolean | null>(null)
  const [note, setNote] = useState('')
  const [error, setError] = useState<string | null>(null)

  if (requestId == null) return null

  async function submit() {
    if (requestId == null) return
    if (showedUp == null) {
      setError(t('report.choose'))
      return
    }
    const trimmed = note.trim()
    if (trimmed.length > noteLimit) {
      setError(t('report.noteTooLong'))
      return
    }
    setError(null)
    try {
      await confirm.mutateAsync({
        requestId,
        driverShowedUp: showedUp,
        note: trimmed === '' ? undefined : trimmed,
      })
      toast(t('report.success'), 'success')
    } catch (caught) {
      setError(
        caught instanceof ApiError && caught.status === 409
          ? t('report.alreadyClosed')
          : t('common.error'),
      )
    }
  }

  return (
    <section
      id="post-trip-report"
      className="flex flex-col gap-3"
      aria-label={t('report.question')}
    >
      <h3 className="text-sm font-semibold text-navy">{t('report.question')}</h3>
      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          className={showedUp === true ? primaryButtonClass : secondaryButtonClass}
          aria-pressed={showedUp === true}
          disabled={confirm.isPending}
          onClick={() => {
            setShowedUp(true)
            setError(null)
          }}
        >
          {t('report.showedUp')}
        </button>
        <button
          type="button"
          className={showedUp === false ? primaryButtonClass : secondaryButtonClass}
          aria-pressed={showedUp === false}
          disabled={confirm.isPending}
          onClick={() => {
            setShowedUp(false)
            setError(null)
          }}
        >
          {t('report.didNotShow')}
        </button>
      </div>
      <label className="flex flex-col gap-1.5 text-sm font-semibold text-navy">
        {t('report.note')}
        <textarea
          className={`${controlClass} h-24 py-2`}
          maxLength={noteLimit}
          value={note}
          disabled={confirm.isPending}
          onChange={(event) => setNote(event.target.value)}
        />
      </label>
      {error ? (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      ) : null}
      <button
        type="button"
        className={primaryButtonClass}
        disabled={confirm.isPending}
        onClick={() => {
          void submit()
        }}
      >
        {confirm.isPending ? t('common.loading') : t('report.submit')}
      </button>
    </section>
  )
}
