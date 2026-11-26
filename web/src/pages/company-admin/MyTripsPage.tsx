import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { TripSummary } from '../../api/types'
import { myTripsQuery, type MyTripsTab } from '../../api/company-queries'
import { useMyTrips, useTrip } from '../../api/use-trips'
import { PageHeading } from '../../components/layout/AppShell'
import { FilterBar } from '../../components/ui/FilterBar'
import { TripPhase } from '../../components/trips/TripPhase'
import { tripColumns } from '../../components/trips/trip-columns'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { FilterSelect } from '../../components/ui/FilterSelect'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { trackingChipStatus } from '../../lib/request-tracking'
import { ghostButtonClass, primaryButtonClass } from '../../components/ui/styles'
import { messageForApiError } from '../../lib/api-message'
import { useListParams } from '../../lib/use-list-params'
import { OwnTripReport } from '../../components/trips/OwnTripReport'
import { RequestTripDialog } from './RequestTripDialog'
import { TripDetailDialog } from './TripDetailDialog'

const TABS: MyTripsTab[] = ['all', 'active', 'completed', 'cancelled']

function readTab(value: string | null): MyTripsTab {
  if (value === 'active' || value === 'completed' || value === 'cancelled' || value === 'all') {
    return value
  }
  return 'all'
}

export function MyTripsPage() {
  const { t, i18n } = useTranslation()
  const { params, set, page, setPage, countActive, clear } = useListParams()
  const tab = readTab(params.get('tab'))
  const query = useMemo(() => myTripsQuery(tab, page), [tab, page])
  const list = useMyTrips(query)
  const selectedId = params.get('trip')
  const detail = useTrip(selectedId, { poll: true })
  const [formOpen, setFormOpen] = useState(false)
  const showReport = params.get('report') === '1'

  useEffect(() => {
    if (!showReport || !detail.data) return
    document.getElementById('post-trip-report')?.scrollIntoView({ block: 'center' })
  }, [showReport, detail.data])

  const columns = useMemo<Column<TripSummary>[]>(
    () =>
      tripColumns<TripSummary>(t, i18n.language, {
        phase: (trip) => (
          <span className="inline-flex flex-wrap items-center gap-2">
            {trip.tracking ? (
              <StatusBadge status={trackingChipStatus(trip.tracking.stage)} />
            ) : (
              <TripPhase status={trip.status} confirmation={trip.confirmation_status} />
            )}
            {trip.confirmation_status === 'unconfirmed' ? (
              <StatusBadge status="unconfirmed" />
            ) : null}
          </span>
        ),
        actions: (trip) => (
          <button
            type="button"
            className={ghostButtonClass}
            onClick={() => set({ trip: trip.id }, false)}
          >
            {t('common.view')}
          </button>
        ),
      }),
    [i18n.language, set, t],
  )

  const rows = list.data?.data ?? []

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.myTrips')}>
        <button type="button" className={primaryButtonClass} onClick={() => setFormOpen(true)}>
          {t('myTrips.request')}
        </button>
      </PageHeading>
      <FilterBar activeCount={countActive(['tab'])} onClear={() => clear(['tab'])}>
        <FilterSelect
          label={t('myTrips.tabs')}
          value={tab}
          onChange={(next) => set({ tab: next === 'all' ? null : next })}
          options={TABS.map((item) => ({ value: item, label: t(`myTrips.${item}`) }))}
        />
      </FilterBar>
      <DataTable
        columns={columns}
        rows={rows}
        rowKey={(row) => row.id}
        isLoading={list.isPending}
        error={list.isError ? messageForApiError(list.error, t) : null}
        onRetry={() => {
          void list.refetch()
        }}
        empty={{
          message: t('myTrips.empty'),
          action:
            countActive(['tab']) > 0
              ? { label: t('filters.clear'), onClick: () => clear(['tab']) }
              : undefined,
        }}
        total={list.data?.meta.total}
        onRowClick={(row) => set({ trip: row.id }, false)}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <TripDetailDialog
        trip={selectedId ? (detail.data ?? null) : null}
        isLoading={selectedId !== null && detail.isPending}
        error={selectedId && detail.isError ? messageForApiError(detail.error, t) : null}
        onClose={() => set({ trip: null, report: null })}
        report={selectedId && detail.data ? <OwnTripReport trip={detail.data} /> : null}
      />
      <RequestTripDialog open={formOpen} onClose={() => setFormOpen(false)} />
    </section>
  )
}
