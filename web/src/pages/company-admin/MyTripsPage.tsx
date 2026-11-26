import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { TripSummary } from '../../api/types'
import { myTripsQuery, type MyTripsTab } from '../../api/company-queries'
import { useMyTrips, useTrip } from '../../api/use-trips'
import { PageHeading } from '../../components/layout/AppShell'
import { FilterBar } from '../../components/ui/FilterBar'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { FilterSelect } from '../../components/ui/FilterSelect'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { trackingChipStatus } from '../../lib/request-tracking'
import { primaryButtonClass, secondaryButtonClass } from '../../components/ui/styles'
import { messageForApiError } from '../../lib/api-message'
import { formatWhen } from '../../lib/format'
import { localizedName } from '../../lib/names'
import { tripStage } from '../../lib/trip-stage'
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
    () => [
      {
        id: 'when',
        header: t('trips.scheduled'),
        sortValue: (row) => row.scheduled_at,
        accessor: (row) => formatWhen(row.scheduled_at, i18n.language),
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
        id: 'status',
        header: t('requests.status'),
        accessor: (row) => (
          <StatusBadge
            status={row.tracking ? trackingChipStatus(row.tracking.stage) : row.status}
          />
        ),
      },
      {
        id: 'stage',
        header: t('trips.stage'),
        accessor: (row) => <StatusBadge status={tripStage(row)} />,
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
        id: 'actions',
        header: t('common.actions'),
        accessor: (row) => (
          <button
            type="button"
            className={secondaryButtonClass}
            onClick={() => set({ trip: row.id }, false)}
          >
            {t('common.view')}
          </button>
        ),
      },
    ],
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
        emptyLabel={t('myTrips.empty')}
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
