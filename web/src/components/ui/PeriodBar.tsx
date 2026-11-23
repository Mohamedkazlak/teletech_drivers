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
      <div className="flex min-w-64 flex-1 items-center gap-2 pb-0.5">
        <button
          type="button"
          className="h-10 rounded-control border-[1.5px] border-deep bg-white px-3 text-sm font-bold text-deep disabled:opacity-40"
          aria-label={t('period.previous')}
          disabled={value.period === 'all'}
          onClick={() => move(-1)}
        >
          {t('common.previous')}
        </button>
        <p className="min-w-0 flex-1 text-center text-sm text-navy/75">{range}</p>
        <button
          type="button"
          className="h-10 rounded-control border-[1.5px] border-deep bg-white px-3 text-sm font-bold text-deep disabled:opacity-40"
          aria-label={t('period.next')}
          disabled={value.period === 'all'}
          onClick={() => move(1)}
        >
          {t('common.next')}
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
