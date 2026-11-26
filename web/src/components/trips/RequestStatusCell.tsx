import { useTranslation } from 'react-i18next'
import type { TripRequestStatus } from '../../api/types'
import { StatusBadge } from '../ui/StatusBadge'

type RequestStatusCellProps = {
  status: TripRequestStatus
  tripId: string | null
}

/** The request's status chip plus who has to act next, when someone does. */
export function RequestStatusCell({ status, tripId }: RequestStatusCellProps) {
  const { t } = useTranslation()
  const waiting =
    status === 'pending'
      ? t('requests.waitingOn.company')
      : status === 'approved' && !tripId
        ? t('requests.waitingOn.drivers')
        : null

  return (
    <span className="flex flex-col items-start gap-1">
      <StatusBadge status={status} />
      {waiting ? <span className="text-xs text-ink-muted">{waiting}</span> : null}
    </span>
  )
}
