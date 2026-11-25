import { useTranslation } from 'react-i18next'
import type { RealtimeStatus } from '../../realtime/use-fleet-realtime'

const dotClass: Record<RealtimeStatus, string> = {
  connected: 'bg-success',
  connecting: 'bg-warning',
  disconnected: 'bg-ink-muted/60',
}

/** Live-updates indicator: a dot that pulses while connected. */
export function ConnectionStatus({ status }: { status: RealtimeStatus }) {
  const { t } = useTranslation()
  const label = t(`realtime.${status}`)

  return (
    <p
      className="hidden h-8 items-center gap-2 rounded-full bg-scaffold px-3 text-xs font-medium text-ink-muted ring-1 ring-line md:inline-flex"
      role="status"
    >
      <span aria-hidden="true" className="relative inline-flex h-2 w-2">
        {status === 'connected' ? (
          <span className="absolute inset-0 rounded-full bg-success animate-pulse-ring" />
        ) : null}
        <span className={`relative inline-block h-2 w-2 rounded-full ${dotClass[status]}`} />
      </span>
      {label}
    </p>
  )
}
