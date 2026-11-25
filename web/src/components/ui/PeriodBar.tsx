import { format } from 'date-fns'
import { ar, enUS } from 'date-fns/locale'
import { useTranslation } from 'react-i18next'
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
import { FilterSelect } from './FilterSelect'

const DEFAULT_PERIODS: PeriodKind[] = ['week', 'month', 'year', 'all']

type PeriodBarProps = {
  value: PeriodSelection
  onChange: (value: PeriodSelection) => void
  periods?: readonly PeriodKind[]
}

export function PeriodBar({ value, onChange, periods = DEFAULT_PERIODS }: PeriodBarProps) {
  const { t, i18n } = useTranslation()
  const locale = i18n.language.startsWith('ar') ? ar : enUS
  const anchor = value.date ? parseDateParam(value.date) : new Date()
  const range = describeRange(value.period, anchor, locale)

  function select(period: PeriodKind) {
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

  return (
    <div className="flex flex-wrap items-end gap-3">
      <FilterSelect
        label={t('period.label')}
        value={value.period}
        onChange={(next) => select(next as PeriodKind)}
        options={periods.map((period) => ({ value: period, label: t(`period.${period}`) }))}
      />
      <div className="flex h-[var(--control-height)] min-w-64 flex-1 items-center gap-1 rounded-control border border-line bg-white p-1">
        <button
          type="button"
          className="inline-flex h-full w-9 shrink-0 items-center justify-center rounded-[9px] text-deep transition-[background-color,transform] duration-150 hover:bg-pale active:scale-90 disabled:opacity-30 disabled:hover:bg-transparent"
          aria-label={t('period.previous')}
          disabled={value.period === 'all'}
          onClick={() => move(-1)}
        >
          <ChevronStartIcon size={18} />
        </button>
        <p
          key={range}
          className="min-w-0 flex-1 truncate text-center text-sm font-medium text-navy tabular animate-fade"
        >
          {range || t('period.all')}
        </p>
        <button
          type="button"
          className="inline-flex h-full w-9 shrink-0 items-center justify-center rounded-[9px] text-deep transition-[background-color,transform] duration-150 hover:bg-pale active:scale-90 disabled:opacity-30 disabled:hover:bg-transparent"
          aria-label={t('period.next')}
          disabled={value.period === 'all'}
          onClick={() => move(1)}
        >
          <ChevronEndIcon size={18} />
        </button>
      </div>
    </div>
  )
}

function describeRange(period: PeriodKind, anchor: Date, locale: typeof enUS): string {
  if (period === 'all') return ''
  if (period === 'day') return format(anchor, 'd MMM yyyy', { locale })
  if (period === 'week') {
    const start = startOfFleetWeek(anchor)
    const end = endOfFleetWeek(anchor)
    return `${format(start, 'd MMM', { locale })} – ${format(end, 'd MMM yyyy', { locale })}`
  }
  if (period === 'month') return format(anchor, 'MMMM yyyy', { locale })
  return format(anchor, 'yyyy', { locale })
}
