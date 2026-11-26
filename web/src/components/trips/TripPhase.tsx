import { useTranslation } from 'react-i18next'
import type { TripConfirmationStatus, TripStatus } from '../../api/types'
import { StatusBadge } from '../ui/StatusBadge'

const STEPS = ['assigned', 'going', 'at_destination', 'returning', 'completed'] as const
const MOVING = new Set<TripStatus>(['going', 'at_destination', 'returning'])

type TripPhaseProps = {
  status: TripStatus
  confirmation?: TripConfirmationStatus | null
}

/*
  Five dots on a line: assigned → going → at destination → returning →
  completed. Done steps fill, the current one is a ring that pulses only while
  the car is moving. Unassigned, cancelled and awaiting-report trips show their
  status chip instead.
*/
export function TripPhase({ status, confirmation }: TripPhaseProps) {
  const { t } = useTranslation()
  const step = STEPS.indexOf(status as (typeof STEPS)[number])

  if (step < 0) return <StatusBadge status={status} />
  if (status === 'completed' && confirmation === 'pending') {
    return <StatusBadge status="awaiting_report" />
  }

  const label = t(`status.${status}`)
  const live = MOVING.has(status)

  return (
    <span className="inline-flex items-center gap-2.5">
      <span
        role="img"
        aria-label={t('trips.phaseOf', { step: step + 1, total: STEPS.length, label })}
        className="relative inline-flex items-center gap-1"
      >
        {STEPS.map((item, index) => {
          const done = index < step || status === 'completed'
          const current = index === step && status !== 'completed'
          return (
            <span key={item} className="relative inline-flex items-center gap-1">
              {index > 0 ? (
                <span
                  aria-hidden="true"
                  className={`h-[1.5px] w-2 rounded-full ${index <= step ? 'bg-deep' : 'bg-line'}`}
                />
              ) : null}
              <span
                aria-hidden="true"
                className={`relative size-2 rounded-full ${
                  current
                    ? 'border-2 border-signal bg-white'
                    : done
                      ? status === 'completed'
                        ? 'bg-success'
                        : 'bg-deep'
                      : 'bg-line'
                }`}
              >
                {current && live ? (
                  <span
                    data-live=""
                    className="absolute -inset-1 rounded-full bg-signal/30 animate-pulse-ring motion-reduce:hidden"
                  />
                ) : null}
              </span>
            </span>
          )
        })}
      </span>
      <span className="text-sm text-navy">{label}</span>
    </span>
  )
}
