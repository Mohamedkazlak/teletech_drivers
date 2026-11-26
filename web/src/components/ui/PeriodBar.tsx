import { format, isSameDay } from 'date-fns'
import { ar, enUS } from 'date-fns/locale'
import { motion, useReducedMotion } from 'motion/react'
import { useId, useRef, type KeyboardEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { DURATION, EASE_IN_OUT } from '../../lib/motion'
import {
  endOfFleetWeek,
  formatDateParam,
  parseDateParam,
  shiftAnchor,
  startOfFleetWeek,
  type PeriodKind,
  type PeriodSelection,
} from '../../lib/period'
import { ChevronEndIcon, ChevronStartIcon } from '../icons'

const DEFAULT_PERIODS: PeriodKind[] = ['week', 'month', 'year', 'all']

type PeriodControlProps = {
  value: PeriodSelection
  onChange: (value: PeriodSelection) => void
  periods?: readonly PeriodKind[]
}

const stepButtonClass =
  'inline-flex h-full w-9 shrink-0 items-center justify-center rounded-[9px] text-deep transition-[background-color,transform] duration-150 hover:bg-pale active:scale-90'

/*
  Segmented period switch (Week / Month / …) with a sliding thumb, followed by
  a stepper for the range. "All" has no range, so the stepper goes away.
*/
export function PeriodControl({ value, onChange, periods = DEFAULT_PERIODS }: PeriodControlProps) {
  const { t, i18n } = useTranslation()
  const reduce = useReducedMotion()
  const thumbId = useId()
  const groupRef = useRef<HTMLDivElement>(null)
  const locale = i18n.language.startsWith('ar') ? ar : enUS
  const anchor = value.date ? parseDateParam(value.date) : new Date()
  const range =
    value.period === 'day' && isSameDay(anchor, new Date())
      ? t('period.today')
      : describeRange(value.period, anchor, locale)

  function select(period: PeriodKind) {
    if (period === value.period) return
    if (period === 'all') {
      onChange({ period })
      return
    }
    onChange({ period, date: formatDateParam(anchor) })
  }

  function move(direction: -1 | 1) {
    if (value.period === 'all') return
    const next = shiftAnchor(value.period, anchor, direction)
    onChange({ period: value.period, date: formatDateParam(next) })
  }

  function onKeyDown(event: KeyboardEvent<HTMLDivElement>) {
    const rtl = getComputedStyle(event.currentTarget).direction === 'rtl'
    const forward = rtl ? 'ArrowLeft' : 'ArrowRight'
    const backward = rtl ? 'ArrowRight' : 'ArrowLeft'
    const index = periods.indexOf(value.period)
    let next = -1
    if (event.key === forward || event.key === 'ArrowDown') next = (index + 1) % periods.length
    if (event.key === backward || event.key === 'ArrowUp')
      next = (index - 1 + periods.length) % periods.length
    if (next < 0) return
    event.preventDefault()
    select(periods[next])
    const buttons = groupRef.current?.querySelectorAll<HTMLButtonElement>('[role="radio"]')
    buttons?.[next]?.focus()
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      <div
        ref={groupRef}
        role="radiogroup"
        aria-label={t('period.label')}
        onKeyDown={onKeyDown}
        className="inline-flex h-[var(--control-height)] items-center gap-0.5 rounded-control border border-line bg-white p-1"
      >
        {periods.map((period) => {
          const checked = period === value.period
          return (
            <button
              key={period}
              type="button"
              role="radio"
              aria-checked={checked}
              tabIndex={checked ? 0 : -1}
              onClick={() => select(period)}
              className={`relative h-full rounded-[9px] px-3 text-sm font-semibold transition-colors duration-150 ${
                checked ? 'text-white' : 'text-ink-muted hover:text-navy'
              }`}
            >
              {checked ? (
                <motion.span
                  layoutId={thumbId}
                  aria-hidden="true"
                  className="absolute inset-0 rounded-[9px] bg-deep shadow-button"
                  transition={
                    reduce ? { duration: 0 } : { duration: DURATION.standard, ease: EASE_IN_OUT }
                  }
                />
              ) : null}
              <span className="relative">{t(`period.${period}`)}</span>
            </button>
          )
        })}
      </div>
      {value.period === 'all' ? null : (
        <div className="flex h-[var(--control-height)] min-w-56 flex-1 items-center gap-1 rounded-control border border-line bg-white p-1 sm:flex-none">
          <button
            type="button"
            className={stepButtonClass}
            aria-label={t('period.previous')}
            onClick={() => move(-1)}
          >
            <ChevronStartIcon size={18} />
          </button>
          <p
            key={range}
            aria-live="polite"
            className="min-w-0 flex-1 truncate px-1 text-center text-sm font-medium text-navy tabular animate-fade"
          >
            {range}
          </p>
          <button
            type="button"
            className={stepButtonClass}
            aria-label={t('period.next')}
            onClick={() => move(1)}
          >
            <ChevronEndIcon size={18} />
          </button>
        </div>
      )}
    </div>
  )
}

/** Kept while pages move to PeriodControl. */
export const PeriodBar = PeriodControl

function describeRange(period: PeriodKind, anchor: Date, locale: typeof enUS): string {
  if (period === 'all') return ''
  if (period === 'day') return format(anchor, 'EEE d MMM yyyy', { locale })
  if (period === 'week') {
    const start = startOfFleetWeek(anchor)
    const end = endOfFleetWeek(anchor)
    return `${format(start, 'd MMM', { locale })} – ${format(end, 'd MMM yyyy', { locale })}`
  }
  if (period === 'month') return format(anchor, 'MMMM yyyy', { locale })
  return format(anchor, 'yyyy', { locale })
}
