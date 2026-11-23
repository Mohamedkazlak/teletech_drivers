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
const tones: Record<string, string> = {
  pending: 'bg-warning/14 text-warning',
  unassigned: 'bg-warning/14 text-warning',
  unconfirmed: 'bg-warning/14 text-warning',
  awaiting_report: 'bg-warning/14 text-warning',
  approved: 'bg-mid/14 text-mid',
  assigned: 'bg-mid/14 text-mid',
  driver_assigned: 'bg-mid/14 text-mid',
  at_destination: 'bg-mid/14 text-mid',
  confirmed: 'bg-success/14 text-success',
  available: 'bg-success/14 text-success',
  checked_in: 'bg-success/14 text-success',
  present: 'bg-success/14 text-success',
  checked_out: 'bg-mid/14 text-mid',
  absent: 'bg-warning/14 text-warning',
  not_checked_in: 'bg-warning/14 text-warning',
  active: 'bg-success/14 text-success',
  completed: 'bg-success/14 text-success',
  in_progress: 'bg-deep/14 text-deep',
  going: 'bg-deep/14 text-deep',
  returning: 'bg-deep/14 text-deep',
  on_trip: 'bg-deep/14 text-deep',
  rejected: 'bg-danger/14 text-danger',
  cancelled: 'bg-danger/14 text-danger',
  unavailable: 'bg-navy/10 text-navy/45',
  finished_today: 'bg-warning/14 text-warning',
  inactive: 'bg-navy/10 text-navy/45',
  deleted: 'bg-navy/10 text-navy/45',
}

export function StatusBadge({ status }: { status: string }) {
  const { t } = useTranslation()
  const label = t(`status.${status}`, { defaultValue: status.replaceAll('_', ' ') })
  return (
    <span
      className={`inline-flex items-center rounded-chip px-2 py-0.5 text-sm font-bold ${tones[status] ?? 'bg-pale text-navy'}`}
    >
      {label}
    </span>
  )
}
