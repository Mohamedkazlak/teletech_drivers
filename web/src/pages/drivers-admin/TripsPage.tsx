import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Branch, TripSummary } from '../../api/types'
import {
  DRIVERS_TRIP_TABS,
  driversTripsQuery,
  type DriversTripTab,
} from '../../api/drivers-queries'
import { PageHeading } from '../../components/layout/AppShell'
import { BranchFilter, type BranchFilterValue } from '../../components/ui/BranchFilter'
import { FilterBar } from '../../components/ui/FilterBar'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { FilterSelect } from '../../components/ui/FilterSelect'
import { PeriodControl } from '../../components/ui/PeriodControl'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { secondaryButtonClass } from '../../components/ui/styles'
import { messageForApiError } from '../../lib/api-message'
import { formatWhen } from '../../lib/format'
import { isBranch, localizedName } from '../../lib/names'
import { formatDateParam } from '../../lib/period'
import { readTripPeriod, TRIP_PERIODS } from '../../lib/trip-period'
import { useListParams } from '../../lib/use-list-params'
import { useTrips } from '../../api/use-trips'
import { FleetTripDetail } from './FleetTripDetail'

function readTab(value: string | null): DriversTripTab {
  if (value === 'assigned' || value === 'in_progress' || value === 'completed') return value
  return 'unassigned'
}

function readBranch(value: string | null): BranchFilterValue {
  return isBranch(value) ? value : ''
}

const FILTER_KEYS = ['stage', 'branch', 'period', 'date'] as const

export function TripsPage() {
  const { t, i18n } = useTranslation()
  const { params, set, page, setPage, countActive, clear } = useListParams()
  const tab = readTab(params.get('stage'))
  const branch = readBranch(params.get('branch'))
  const period = readTripPeriod(params.get('period'))
  const date = params.get('date') || formatDateParam(new Date())
  const query = useMemo(
    () => driversTripsQuery({ tab, branch, period, date, page }),
    [tab, branch, period, date, page],
  )
  const list = useTrips(query)
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const columns = useMemo<Column<TripSummary>[]>(
    () => [
      {
        id: 'people',
        header: t('trips.people'),
        accessor: (row) => peopleLabel(row, i18n.language, t('common.dash')),
      },
      {
        id: 'route',
        header: t('requests.route'),
        accessor: (row) =>
          t('requests.routeValue', {
            from: row.pickup_summary || t('common.dash'),
            to: row.destination_summary || t('common.dash'),
          }),
      },
      {
        id: 'driver',
        header: t('trips.driver'),
        accessor: (row) =>
          row.driver
            ? localizedName(i18n.language, row.driver.name_en, row.driver.name_ar)
            : t('trips.unassigned'),
      },
      {
        id: 'status',
        header: t('requests.status'),
        accessor: (row) => (
          <span className="inline-flex flex-wrap gap-1">
            <StatusBadge status={row.status} />
            {row.confirmation_status === 'unconfirmed' ? (
              <StatusBadge status="unconfirmed" />
            ) : null}
          </span>
        ),
      },
      {
        id: 'when',
        header: t('trips.scheduled'),
        sortValue: (row) => row.scheduled_at,
        accessor: (row) => (
          <span>
            <span>{formatWhen(row.scheduled_at, i18n.language)}</span>
            {row.going_started_at || row.finished_at ? (
              <span className="mt-1 block text-xs text-ink-muted">
                {formatWhen(row.going_started_at, i18n.language) || t('common.dash')}
                {' – '}
                {formatWhen(row.finished_at, i18n.language) || t('common.dash')}
              </span>
            ) : null}
          </span>
        ),
      },
      {
        id: 'actions',
        header: t('common.actions'),
        accessor: (row) => (
          <button
            type="button"
            className={secondaryButtonClass}
            onClick={() => setSelectedId(row.id)}
          >
            {t('common.view')}
          </button>
        ),
      },
    ],
    [i18n.language, t],
  )

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.trips')} />
      <FilterBar activeCount={countActive(FILTER_KEYS)} onClear={() => clear(FILTER_KEYS)}>
        <FilterSelect
          label={t('trips.stage')}
          value={tab}
          onChange={(next) => set({ stage: next === 'unassigned' ? null : next })}
          options={DRIVERS_TRIP_TABS.map((item) => ({ value: item, label: t(`status.${item}`) }))}
        />
        <BranchFilter
          value={branch}
          onChange={(next: Branch | '') => set({ branch: next || null })}
        />
        <PeriodControl
          periods={TRIP_PERIODS}
          value={{ period, date: period === 'all' ? undefined : date }}
          onChange={(next) => set({ period: next.period, date: next.date ?? null })}
        />
      </FilterBar>
      <DataTable
        columns={columns}
        rows={list.data?.data ?? []}
        rowKey={(row) => row.id}
        isLoading={list.isPending}
        error={list.isError ? messageForApiError(list.error, t) : null}
        onRetry={() => {
          void list.refetch()
        }}
        empty={{
          message: t('trips.empty'),
          action:
            countActive(FILTER_KEYS) > 0
              ? { label: t('filters.clear'), onClick: () => clear(FILTER_KEYS) }
              : undefined,
        }}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <FleetTripDetail tripId={selectedId} onClose={() => setSelectedId(null)} />
    </section>
  )
}

function peopleLabel(trip: TripSummary, language: string, empty: string): string {
  const names = trip.passengers
    .map((passenger) => localizedName(language, passenger.name_en, passenger.name_ar))
    .filter((name) => name !== '')
  return names.length > 0 ? names.join(', ') : empty
}
