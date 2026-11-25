import { useTranslation } from 'react-i18next'

/*
  Chip fills use the status color at 14% alpha, matching StatusChip.
  pending / unassigned → warning
  approved / assigned / at destination → mid blue
  in progress (going, returning, on trip) → deep blue
  completed → success
  rejected and trip cancelled → error (AppColors.statusRejected)
  unavailable / inactive / deleted → navy at 45%
*/
const LIVE = new Set(['in_progress', 'going', 'returning', 'on_trip', 'checked_in'])

const tones: Record<string, string> = {
  pending: 'bg-warning/14 text-warning-ink [--dot:var(--color-warning)]',
  unassigned: 'bg-warning/14 text-warning-ink [--dot:var(--color-warning)]',
  unconfirmed: 'bg-warning/14 text-warning-ink [--dot:var(--color-warning)]',
  awaiting_report: 'bg-warning/14 text-warning-ink [--dot:var(--color-warning)]',
  approved: 'bg-mid/12 text-deep [--dot:var(--color-mid)]',
  assigned: 'bg-mid/12 text-deep [--dot:var(--color-mid)]',
  driver_assigned: 'bg-mid/12 text-deep [--dot:var(--color-mid)]',
  at_destination: 'bg-mid/12 text-deep [--dot:var(--color-mid)]',
  confirmed: 'bg-success/12 text-success-ink [--dot:var(--color-success)]',
  available: 'bg-success/12 text-success-ink [--dot:var(--color-success)]',
  checked_in: 'bg-success/12 text-success-ink [--dot:var(--color-success)]',
  present: 'bg-success/12 text-success-ink [--dot:var(--color-success)]',
  checked_out: 'bg-mid/12 text-deep [--dot:var(--color-mid)]',
  absent: 'bg-warning/14 text-warning-ink [--dot:var(--color-warning)]',
  not_checked_in: 'bg-warning/14 text-warning-ink [--dot:var(--color-warning)]',
  active: 'bg-success/12 text-success-ink [--dot:var(--color-success)]',
  completed: 'bg-success/12 text-success-ink [--dot:var(--color-success)]',
  in_progress: 'bg-signal/12 text-deep [--dot:var(--color-signal)]',
  going: 'bg-signal/12 text-deep [--dot:var(--color-signal)]',
  returning: 'bg-signal/12 text-deep [--dot:var(--color-signal)]',
  on_trip: 'bg-signal/12 text-deep [--dot:var(--color-signal)]',
  rejected: 'bg-danger/10 text-danger-ink [--dot:var(--color-danger)]',
  cancelled: 'bg-danger/10 text-danger-ink [--dot:var(--color-danger)]',
  unavailable: 'bg-navy/[0.06] text-ink-muted [--dot:var(--color-ink-muted)]',
  finished_today: 'bg-warning/14 text-warning-ink [--dot:var(--color-warning)]',
  inactive: 'bg-navy/[0.06] text-ink-muted [--dot:var(--color-ink-muted)]',
  deleted: 'bg-navy/[0.06] text-ink-muted [--dot:var(--color-ink-muted)]',
}

export function StatusBadge({ status }: { status: string }) {
  const { t } = useTranslation()
  const label = t(`status.${status}`, { defaultValue: status.replaceAll('_', ' ') })
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-chip py-0.5 pe-2.5 ps-2 text-[13px] font-semibold whitespace-nowrap transition-colors duration-200 ${tones[status] ?? 'bg-pale text-navy [--dot:var(--color-mid)]'}`}
    >
      <span aria-hidden="true" className="relative inline-flex h-1.5 w-1.5">
        {LIVE.has(status) ? (
          <span className="absolute inset-0 rounded-full bg-[var(--dot)] animate-pulse-ring" />
        ) : null}
        <span className="relative h-1.5 w-1.5 rounded-full bg-[var(--dot)]" />
      </span>
      {label}
    </span>
  )
}
