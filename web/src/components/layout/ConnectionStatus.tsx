import { useTranslation } from 'react-i18next'
import type { RealtimeStatus } from '../../realtime/use-fleet-realtime'

const dotClass: Record<RealtimeStatus, string> = {
  connected: 'bg-success',
  connecting: 'bg-warning',
  disconnected: 'bg-navy/45',
}

export function ConnectionStatus({ status }: { status: RealtimeStatus }) {
  const { t } = useTranslation()
  const label = t(`realtime.${status}`)

  return (
    <p className="inline-flex items-center gap-1.5 text-xs text-navy/75" role="status">
      <span
        aria-hidden="true"
        className={`inline-block h-2 w-2 rounded-full ${dotClass[status]}`}
      />
      {label}
    </p>
  )
}
