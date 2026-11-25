import type { TFunction } from 'i18next'
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { driverActivityQuery } from '../../api/drivers'
import { PAGE_SIZE } from '../../api/to-query'
import type { Driver, DriverCompletedTrip, DriverStats, FleetPeriod, Place } from '../../api/types'
import { useDriver, useDriverStats, useDriverTrips } from '../../api/use-drivers'
import { useActivePlaces } from '../../api/use-places'
import { BarChartCard } from '../../components/charts/BarChartCard'
import { PageHeading } from '../../components/layout/AppShell'
import { BackArrow } from '../../components/layout/BackButton'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { DetailList } from '../../components/ui/DetailList'
import { PeriodBar } from '../../components/ui/PeriodBar'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { secondaryButtonClass } from '../../components/ui/styles'
import { messageForApiError } from '../../lib/api-message'
import { formatDistanceKm, formatDuration, formatWhen } from '../../lib/format'
import { localizedName } from '../../lib/names'
import { formatDateParam, type PeriodKind, type PeriodSelection } from '../../lib/period'
import { DriverAttendanceSection } from './DriverAttendanceSection'
import { ExportReportDialog } from './ExportReportDialog'

const PROFILE_PERIODS: PeriodKind[] = ['week', 'month', 'year', 'all']

export function DriverProfilePage() {
  const { driverId = '' } = useParams()
  return <DriverProfile key={driverId} driverId={driverId} />
}

function DriverProfile({ driverId }: { driverId: string }) {
  const { t, i18n } = useTranslation()
  const driver = useDriver(driverId)
  const places = useActivePlaces(true)
  const [selection, setSelection] = useState<PeriodSelection>(() => ({
    period: 'week',
    date: formatDateParam(new Date()),
  }))
  const [tripPage, setTripPage] = useState(1)
  const [exportOpen, setExportOpen] = useState(false)
  const period = activityPeriod(selection)
  const statsQuery = driverActivityQuery(period, selection.date)
  const stats = useDriverStats(driverId, statsQuery)
  const trips = useDriverTrips(driverId, {
    ...statsQuery,
    page: tripPage > 1 ? tripPage : undefined,
    per_page: PAGE_SIZE,
  })

  if (driver.isPending) return <p role="status">{t('common.loading')}</p>
  if (driver.isError) {
    return (
      <div className="flex flex-col gap-3">
        <p role="alert" className="text-sm text-danger">
          {messageForApiError(driver.error, t)}
        </p>
        <button
          type="button"
          className={secondaryButtonClass}
          onClick={() => void driver.refetch()}
        >
          {t('common.retry')}
        </button>
      </div>
    )
  }

  const profile = driver.data
  const name = localizedName(i18n.language, profile.name_en, profile.name_ar)

  return (
    <section className="flex flex-col gap-5">
      <Link to=".." className="inline-flex w-fit items-center gap-1 text-sm font-medium text-deep">
        <BackArrow className="h-4 w-4" />
        {t('common.back')}
      </Link>
      <PageHeading title={name || t('driverAdmin.profile')}>
        <button
          type="button"
          className={secondaryButtonClass}
          onClick={() => setExportOpen(true)}
        >
          {t('driverAdmin.exportReport')}
        </button>
      </PageHeading>
      <DetailList
        items={[
          { label: t('profile.nameEn'), value: profile.name_en },
          { label: t('profile.nameAr'), value: profile.name_ar || t('common.dash') },
          { label: t('profile.email'), value: profile.email },
          { label: t('driverAdmin.phone'), value: profile.phone || t('common.dash') },
          { label: t('driverAdmin.nationalId'), value: profile.national_id },
          { label: t('driverAdmin.carLicense'), value: profile.car_license },
          { label: t('driverAdmin.personalLicense'), value: profile.personal_license },
          {
            label: t('driverAdmin.filter'),
            value: (
              <StatusBadge status={profile.is_available ? 'checked_in' : 'not_checked_in'} />
            ),
          },
          {
            label: t('driverAdmin.active'),
            value: <StatusBadge status={profile.is_active ? 'active' : 'inactive'} />,
          },
          ...(profile.deleted_at
            ? [{ label: t('common.deleted'), value: <StatusBadge status="deleted" /> }]
            : []),
          {
            label: t('driverAdmin.favorites'),
            value: favoriteLabel(
              profile,
              places.data ?? [],
              i18n.language,
              t('driverAdmin.favoritesEmpty'),
            ),
          },
        ]}
      />
      <DriverAttendanceSection driverId={driverId} />
      <ExportReportDialog
        open={exportOpen}
        driverId={driverId}
        driverName={name || t('driverAdmin.profile')}
        onClose={() => setExportOpen(false)}
      />
      <Totals
        title={t('driverAdmin.allTime')}
        trips={profile.totals?.trips}
        seconds={profile.totals?.total_seconds}
        km={profile.totals?.total_km}
      />
      <PeriodBar
        value={selection}
        periods={PROFILE_PERIODS}
        onChange={(next) => {
          setSelection(next)
          setTripPage(1)
        }}
      />
      <PeriodStats
        stats={stats.data}
        isPending={stats.isPending}
        error={stats.isError ? messageForApiError(stats.error, t) : null}
        onRetry={() => void stats.refetch()}
      />
      <BarChartCard
        title={t('driverAdmin.chart')}
        points={(stats.data?.breakdown ?? []).map((bucket, index) => ({
          label: bucket.label || String(index + 1),
          value: bucket.trips,
        }))}
      />
      <h2 className="text-base font-semibold text-navy">{t('driverAdmin.completed')}</h2>
      <DataTable
        columns={tripColumns(t, i18n.language)}
        rows={trips.data?.data ?? []}
        rowKey={(row) => row.id}
        isLoading={trips.isPending}
        error={trips.isError ? messageForApiError(trips.error, t) : null}
        onRetry={() => {
          void trips.refetch()
        }}
        emptyLabel={t('driverAdmin.completedEmpty')}
        page={trips.data?.meta.current_page ?? tripPage}
        lastPage={trips.data?.meta.last_page ?? 1}
        onPageChange={setTripPage}
      />
    </section>
  )
}

function PeriodStats({
  stats,
  isPending,
  error,
  onRetry,
}: {
  stats: DriverStats | undefined
  isPending: boolean
  error: string | null
  onRetry: () => void
}) {
  const { t } = useTranslation()
  if (isPending) return <p role="status">{t('common.loading')}</p>
  if (error) {
    return (
      <div>
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
        <button type="button" className={`${secondaryButtonClass} mt-3`} onClick={onRetry}>
          {t('common.retry')}
        </button>
      </div>
    )
  }
  return (
    <Totals
      title={t('driverAdmin.periodTotals')}
      trips={stats?.trips}
      seconds={stats?.total_seconds}
      km={stats?.total_km}
    />
  )
}

function Totals({
  title,
  trips,
  seconds,
  km,
}: {
  title: string
  trips: number | undefined
  seconds: number | undefined
  km: number | undefined
}) {
  const { t, i18n } = useTranslation()
  return (
    <section>
      <h2 className="text-base font-semibold text-navy">{title}</h2>
      <dl className="mt-2 grid gap-3 sm:grid-cols-3">
        <div>
          <dt className="text-xs font-medium text-ink-muted">{t('driverAdmin.trips')}</dt>
          <dd className="text-sm text-navy">{trips ?? t('common.dash')}</dd>
        </div>
        <div>
          <dt className="text-xs font-medium text-ink-muted">{t('driverAdmin.time')}</dt>
          <dd className="text-sm text-navy">
            {seconds == null ? t('common.dash') : formatDuration(seconds, t)}
          </dd>
        </div>
        <div>
          <dt className="text-xs font-medium text-ink-muted">{t('driverAdmin.distance')}</dt>
          <dd className="text-sm text-navy">
            {km == null
              ? t('common.dash')
              : t('format.kilometers', { value: formatDistanceKm(km, i18n.language) })}
          </dd>
        </div>
      </dl>
    </section>
  )
}

function favoriteLabel(driver: Driver, places: Place[], language: string, empty: string): string {
  if (driver.favorite_place_ids.length === 0) return empty
  return driver.favorite_place_ids
    .map((id) => {
      const place = places.find((item) => item.id === id)
      return place ? localizedName(language, place.name_en, place.name_ar) : id
    })
    .join(', ')
}

function activityPeriod(selection: PeriodSelection): FleetPeriod {
  if (selection.period === 'day') return 'week'
  return selection.period
}

function tripColumns(t: TFunction, language: string): Column<DriverCompletedTrip>[] {
  return [
    {
      id: 'when',
      header: t('trips.scheduled'),
      accessor: (row) => formatWhen(row.scheduled_at, language) || t('common.dash'),
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
      id: 'duration',
      header: t('trips.duration'),
      accessor: (row) =>
        row.duration_seconds == null ? t('common.dash') : formatDuration(row.duration_seconds, t),
    },
    {
      id: 'km',
      header: t('driverAdmin.distance'),
      accessor: (row) =>
        row.distance_km == null
          ? t('common.dash')
          : t('format.kilometers', { value: formatDistanceKm(row.distance_km, language) }),
    },
    {
      id: 'confirmation',
      header: t('requests.status'),
      accessor: (row) =>
        row.confirmation_status ? (
          <StatusBadge status={row.confirmation_status} />
        ) : (
          t('common.dash')
        ),
    },
  ]
}
