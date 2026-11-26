import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { TripLifecycle } from '../../api/trips'
import type { Branch, TripStage, TripSummary } from '../../api/types'
import { tripsListQuery } from '../../api/company-queries'
import { overviewStage, useTrip, useTripOverview, useTrips } from '../../api/use-trips'
import { PageHeading } from '../../components/layout/AppShell'
import { BranchFilter, type BranchFilterValue } from '../../components/ui/BranchFilter'
import { FilterBar } from '../../components/ui/FilterBar'
import { tripColumns } from '../../components/trips/trip-columns'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { FilterSelect } from '../../components/ui/FilterSelect'
import { PeriodControl } from '../../components/ui/PeriodControl'
import { ghostButtonClass, secondaryButtonClass } from '../../components/ui/styles'
import { messageForApiError } from '../../lib/api-message'
import { isBranch } from '../../lib/names'
import { formatDateParam } from '../../lib/period'
import {
  readFinishedPeriod,
  readTripPeriod,
  readUnconfirmedParam,
  TRIP_PERIODS,
} from '../../lib/trip-period'
import { useListParams } from '../../lib/use-list-params'
import { TripDetailDialog } from './TripDetailDialog'

const STAGES: TripStage[] = [
  'unassigned',
  'assigned',
  'in_progress',
  'awaiting_report',
  'completed',
  'cancelled',
]

const LIFECYCLES: TripLifecycle[] = ['upcoming', 'in_progress', 'completed', 'cancelled']

function readStage(value: string | null): TripStage | '' {
  return STAGES.find((stage) => stage === value) ?? ''
}

function readLifecycle(value: string | null): TripLifecycle | '' {
  return LIFECYCLES.find((item) => item === value) ?? ''
}

function readBranch(value: string | null): BranchFilterValue {
  return isBranch(value) ? value : ''
}

const FILTER_KEYS = [
  'stage',
  'lifecycle',
  'status',
  'branch',
  'finished_period',
  'unconfirmed',
  'period',
  'date',
] as const

export function TripsPage() {
  const { t, i18n } = useTranslation()
  const { params, set, page, setPage, countActive, clear } = useListParams()
  const branch = readBranch(params.get('branch'))
  const stage = readStage(params.get('stage'))
  const lifecycle = readLifecycle(params.get('lifecycle'))
  const finishedPeriod = readFinishedPeriod(params.get('finished_period'))
  const unconfirmed = readUnconfirmedParam(params.get('unconfirmed'))
  // A finished-at or unconfirmed link must not also apply the default scheduled week.
  const period =
    params.get('period') === null && (finishedPeriod !== '' || unconfirmed)
      ? 'all'
      : readTripPeriod(params.get('period'))
  const date = params.get('date') || formatDateParam(new Date())
  const query = useMemo(
    () =>
      tripsListQuery({
        branch,
        stage,
        status: '',
        lifecycle,
        period,
        date,
        page,
        finishedPeriod,
        unconfirmed,
      }),
    [branch, stage, lifecycle, period, date, page, finishedPeriod, unconfirmed],
  )
  const list = useTrips(query)
  const overview = useTripOverview({
    branch: branch || undefined,
    period: query.period,
    date: query.date,
    finished_period: query.finished_period,
    unconfirmed: query.unconfirmed,
  })
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const detail = useTrip(selectedId)

  const columns = useMemo<Column<TripSummary>[]>(
    () =>
      tripColumns<TripSummary>(t, i18n.language, {
        actions: (trip) => (
          <button type="button" className={ghostButtonClass} onClick={() => setSelectedId(trip.id)}>
            {t('common.view')}
          </button>
        ),
      }),
    [i18n.language, t],
  )

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.trips')} />
      {overview.some((item) => item.isError) ? (
        <div className="flex flex-col items-start gap-3">
          <p role="alert" className="text-sm text-danger">
            {messageForApiError(overview.find((item) => item.isError)?.error, t)}
          </p>
          <button
            type="button"
            className={secondaryButtonClass}
            onClick={() => {
              for (const item of overview) void item.refetch()
            }}
          >
            {t('common.retry')}
          </button>
        </div>
      ) : null}
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {overview.map((item, index) => {
          const itemStage = overviewStage(index)
          return (
            <button
              key={itemStage}
              type="button"
              aria-pressed={stage === itemStage}
              onClick={() =>
                set({
                  stage: stage === itemStage ? null : itemStage,
                  lifecycle: null,
                  status: null,
                })
              }
              className="rounded-card border border-line bg-white px-4 py-3 text-start"
            >
              <p className="text-sm text-ink-muted">{t(`status.${itemStage}`)}</p>
              <p className="mt-1 text-2xl font-semibold text-navy">
                {item.isPending
                  ? t('common.loading')
                  : item.isError
                    ? t('common.dash')
                    : (item.data?.meta.total ?? 0)}
              </p>
            </button>
          )
        })}
      </div>
      <FilterBar activeCount={countActive(FILTER_KEYS)} onClear={() => clear(FILTER_KEYS)}>
        <FilterSelect
          label={t('trips.tripStatus')}
          value={lifecycle}
          onChange={(next) => set({ lifecycle: next || null, stage: null, status: null })}
          options={[
            { value: '', label: t('branch.all') },
            { value: 'upcoming', label: t('trips.upcoming') },
            { value: 'in_progress', label: t('status.in_progress') },
            { value: 'completed', label: t('status.completed') },
            { value: 'cancelled', label: t('status.cancelled') },
          ]}
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
        total={list.data?.meta.total}
        onRowClick={(row) => setSelectedId(row.id)}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <TripDetailDialog
        trip={selectedId ? (detail.data ?? null) : null}
        isLoading={selectedId !== null && detail.isPending}
        error={selectedId && detail.isError ? messageForApiError(detail.error, t) : null}
        onClose={() => setSelectedId(null)}
      />
    </section>
  )
}
