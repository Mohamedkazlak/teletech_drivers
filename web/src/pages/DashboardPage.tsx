import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import type { AdminDashboard } from '../api/types'
import { useAdminDashboard } from '../api/use-dashboard'
import { useTrips } from '../api/use-trips'
import { RingField } from '../components/brand/BrandMark'
import { AlertIcon, ArrowEndIcon, CheckIcon, RefreshIcon } from '../components/icons'
import { PageHeading } from '../components/layout/AppShell'
import { RouteCell } from '../components/trips/RouteCell'
import { TripPhase } from '../components/trips/TripPhase'
import { Counter } from '../components/ui/Counter'
import { EmptyState } from '../components/ui/EmptyState'
import { ghostButtonClass, secondaryButtonClass } from '../components/ui/styles'
import { messageForApiError } from '../lib/api-message'
import { staggerDelay } from '../lib/motion'
import { localizedName } from '../lib/names'

const ON_THE_ROAD_LIMIT = 5

/*
  Status first: today's attendance, then what needs someone to act, then the
  totals in one line, then the trips that are moving right now.
*/
export function DashboardPage() {
  const { t } = useTranslation()
  const dashboard = useAdminDashboard()
  const summary = dashboard.data?.data

  return (
    <section className="flex flex-col gap-7">
      <PageHeading title={t('nav.dashboard')} />
      {dashboard.isPending ? (
        <>
          <p role="status" className="sr-only">
            {t('common.loading')}
          </p>
          <DashboardSkeleton />
        </>
      ) : null}
      {dashboard.isError ? (
        <div className="flex flex-col items-start gap-3 rounded-card border border-danger/25 bg-danger/5 p-5">
          <p role="alert" className="flex items-center gap-2 text-sm text-danger-ink">
            <AlertIcon size={18} />
            {messageForApiError(dashboard.error, t)}
          </p>
          <button
            type="button"
            className={secondaryButtonClass}
            onClick={() => void dashboard.refetch()}
          >
            <RefreshIcon size={16} />
            {t('common.retry')}
          </button>
        </div>
      ) : null}
      {summary ? (
        <>
          <FleetToday summary={summary} />
          <AttentionStrip summary={summary} />
          <TotalsLine summary={summary} />
          <OnTheRoad />
        </>
      ) : null}
    </section>
  )
}

/**
 * The page's one dark surface: today's attendance as a proportional bar
 * (checked in · checked out · absent) next to the trips on the road.
 */
function FleetToday({ summary }: { summary: AdminDashboard }) {
  const { t } = useTranslation()
  const { total, checked_in: checkedIn, checked_out: checkedOut, absent } = summary.drivers
  const segments = [
    {
      key: 'in',
      value: checkedIn,
      label: t('dashboard.driversCheckedIn'),
      color: 'var(--color-hero-in)',
    },
    {
      key: 'out',
      value: checkedOut,
      label: t('dashboard.driversCheckedOut'),
      color: 'var(--color-hero-out)',
    },
    {
      key: 'absent',
      value: absent,
      label: t('dashboard.driversAbsent'),
      color: 'var(--color-hero-absent)',
    },
  ]
  const counted = Math.max(total, checkedIn + checkedOut + absent, 1)

  return (
    <section
      aria-label={t('dashboard.attendanceToday')}
      className="relative overflow-hidden rounded-[22px] bg-[linear-gradient(135deg,var(--color-deep)_0%,var(--color-navy)_55%,var(--color-navy-deep)_100%)] p-6 text-white shadow-float animate-rise sm:p-7"
    >
      <RingField />
      <div className="relative grid gap-7 md:grid-cols-[minmax(0,1.6fr)_minmax(0,1fr)] md:items-end">
        <div>
          <p className="text-sm font-medium text-white/70">{t('dashboard.attendanceToday')}</p>
          <p className="mt-2 flex items-baseline gap-1 text-[17px] font-medium text-white/90">
            <Counter
              value={checkedIn}
              className="text-[44px] leading-none font-semibold tracking-[-0.03em] text-white"
            />
            <span aria-hidden="true" className="text-white/60 tabular">
              / {total}
            </span>
            <span className="sr-only">
              {t('dashboard.checkedInOf', { count: checkedIn, total })}
            </span>
          </p>
          <div
            className="mt-5 flex h-2.5 w-full gap-[3px] overflow-hidden rounded-full bg-white/10"
            aria-hidden="true"
          >
            {segments
              .filter((segment) => segment.value > 0)
              .map((segment, index) => (
                <span
                  key={segment.key}
                  className="h-full origin-left rounded-full rtl:origin-right"
                  style={{
                    flexBasis: `${(segment.value / counted) * 100}%`,
                    background: segment.color,
                    animation: `bar-grow 900ms var(--ease-out) ${150 + index * 90}ms backwards`,
                  }}
                />
              ))}
          </div>
          <ul className="mt-3 flex flex-wrap gap-x-5 gap-y-1.5 text-[13px] text-white/75">
            {segments.map((segment) => (
              <li key={segment.key} className="inline-flex items-center gap-2">
                <span
                  aria-hidden="true"
                  className="h-2 w-2 rounded-full"
                  style={{ background: segment.color }}
                />
                {segment.label}
                <span className="font-semibold text-white tabular">{segment.value}</span>
              </li>
            ))}
          </ul>
        </div>
        <div className="flex gap-3 md:justify-end">
          <HeroFigure label={t('dashboard.liveNow')} value={summary.trips.in_progress} live />
          <HeroFigure label={t('dashboard.waiting')} value={summary.trips.unassigned} />
        </div>
      </div>
    </section>
  )
}

function HeroFigure({
  label,
  value,
  live = false,
}: {
  label: string
  value: number
  live?: boolean
}) {
  return (
    <div className="min-w-[8.5rem] flex-1 rounded-[16px] bg-white/[0.08] px-4 py-3.5 shadow-[inset_0_0_0_1px_rgb(255_255_255/0.08)] md:flex-none">
      <p className="flex items-center gap-2 text-[13px] text-white/70">
        {live && value > 0 ? (
          <span aria-hidden="true" className="relative inline-flex h-2 w-2">
            <span className="absolute inset-0 rounded-full bg-[var(--color-hero-in)] animate-pulse-ring" />
            <span className="relative h-2 w-2 rounded-full bg-[var(--color-hero-in)]" />
          </span>
        ) : null}
        {label}
      </p>
      <Counter
        value={value}
        className="mt-1 text-[28px] leading-none font-semibold tracking-[-0.02em]"
      />
    </div>
  )
}

/** Four things that need someone to act; calm when there's nothing to do. */
function AttentionStrip({ summary }: { summary: AdminDashboard }) {
  const { t } = useTranslation()
  const items = [
    {
      to: '/admin/trips?stage=unassigned',
      label: t('dashboard.tripsUnassigned'),
      value: summary.trips.unassigned,
    },
    {
      to: '/admin/trip-requests?status=pending',
      label: t('dashboard.requestsPending'),
      value: summary.requests.pending,
    },
    {
      to: '/admin/trips?unconfirmed=true',
      label: t('dashboard.unconfirmed'),
      value: summary.unconfirmed_trips,
    },
    {
      to: '/admin/attendance?status=absent',
      label: t('dashboard.absentDrivers'),
      value: summary.drivers.absent,
    },
  ]

  return (
    <section aria-labelledby="attention-heading" className="flex flex-col gap-3">
      <h2 id="attention-heading" className="text-lg font-semibold tracking-[-0.01em] text-navy">
        {t('dashboard.attention')}
      </h2>
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {items.map((item, index) => {
          const needsAction = item.value > 0
          return (
            <Link
              key={item.to}
              to={item.to}
              data-tone={needsAction ? 'warning' : 'calm'}
              style={{ animationDelay: `${staggerDelay(index)}ms` }}
              className={`group flex min-h-[96px] flex-col justify-between rounded-card border px-4 py-3.5 transition-[border-color,transform,background-color] duration-[180ms] ease-[var(--ease-out)] animate-row-in hover:-translate-y-0.5 active:scale-[0.97] motion-reduce:hover:translate-y-0 ${
                needsAction
                  ? 'border-warning/45 bg-warning/[0.07] hover:border-warning/70'
                  : 'border-line bg-white hover:border-deep/35'
              }`}
            >
              <span className="flex items-center gap-2 text-[13px] text-ink-muted">
                {needsAction ? (
                  <span
                    aria-hidden="true"
                    className="h-1.5 w-1.5 shrink-0 rounded-full bg-warning"
                  />
                ) : null}
                {item.label}
              </span>{' '}
              <span className="mt-2 flex items-end justify-between gap-2">
                {needsAction ? (
                  <Counter
                    value={item.value}
                    className="text-[30px] leading-none font-semibold tracking-[-0.02em] text-warning-ink"
                  />
                ) : (
                  <span className="inline-flex items-center gap-1.5 text-sm font-semibold text-success-ink">
                    <CheckIcon size={16} />
                    {t('dashboard.allClear')}
                  </span>
                )}
                <ArrowEndIcon
                  size={18}
                  className="text-deep opacity-0 transition-[opacity,transform] duration-200 ease-[var(--ease-out)] group-hover:translate-x-0.5 group-hover:opacity-100 group-focus-visible:opacity-100 rtl:group-hover:-translate-x-0.5"
                />
              </span>
            </Link>
          )
        })}
      </div>
    </section>
  )
}

/** Totals that don't need action, on one quiet line. */
function TotalsLine({ summary }: { summary: AdminDashboard }) {
  const { t } = useTranslation()
  const items = [
    {
      to: '/admin/drivers',
      value: summary.drivers.total,
      label: t('dashboard.totalDrivers', { count: summary.drivers.total }),
    },
    {
      to: '/admin/employees',
      value: summary.employees_total,
      label: t('dashboard.totalEmployees', { count: summary.employees_total }),
    },
    {
      to: '/admin/places',
      value: summary.places_total,
      label: t('dashboard.totalPlaces', { count: summary.places_total }),
    },
    {
      to: '/admin/trips?stage=completed&finished_period=day',
      value: summary.trips.completed_today,
      label: t('dashboard.totalCompletedToday'),
    },
    {
      to: '/admin/trips?stage=completed&finished_period=week',
      value: summary.trips.completed_this_week,
      label: t('dashboard.totalCompletedWeek'),
    },
  ]

  return (
    <section aria-label={t('dashboard.totals')}>
      <ul className="flex flex-wrap items-center gap-x-1 gap-y-2 rounded-card border border-line bg-white px-2 py-1.5">
        {items.map((item, index) => (
          <li
            key={item.to}
            className="flex items-center animate-row-in"
            style={{ animationDelay: `${staggerDelay(index)}ms` }}
          >
            {index > 0 ? <span aria-hidden="true" className="mx-1 h-4 w-px bg-line" /> : null}
            <Link
              to={item.to}
              className="inline-flex items-baseline gap-1.5 rounded-[10px] px-3 py-2 text-sm text-ink-muted transition-colors duration-150 hover:bg-pale hover:text-navy"
            >
              <Counter value={item.value} className="text-base font-semibold text-navy" />{' '}
              <span>{item.label}</span>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  )
}

/** Up to five trips that are moving right now. */
function OnTheRoad() {
  const { t, i18n } = useTranslation()
  const trips = useTrips({ stage: 'in_progress', per_page: ON_THE_ROAD_LIMIT })
  const rows = trips.data?.data ?? []

  return (
    <section aria-labelledby="road-heading" className="flex flex-col gap-3">
      <div className="flex items-center justify-between gap-3">
        <h2 id="road-heading" className="text-lg font-semibold tracking-[-0.01em] text-navy">
          {t('dashboard.liveNow')}
        </h2>
        <Link to="/admin/trips?stage=in_progress" className={ghostButtonClass}>
          {t('dashboard.viewAll')}
        </Link>
      </div>
      <div className="overflow-hidden rounded-card border border-line bg-white">
        {trips.isPending ? (
          <div aria-hidden="true" className="divide-y divide-line">
            {[0, 1, 2].map((index) => (
              <div key={index} className="flex h-16 items-center gap-6 px-4">
                <span className="skeleton block h-3.5 w-40" />
                <span className="skeleton block h-3.5 w-24" />
              </div>
            ))}
          </div>
        ) : trips.isError ? (
          <p className="px-4 py-6 text-sm text-danger-ink">{messageForApiError(trips.error, t)}</p>
        ) : rows.length === 0 ? (
          <div className="px-4 py-10">
            <EmptyState message={t('dashboard.noneOnRoad')} />
          </div>
        ) : (
          <ul className="divide-y divide-line">
            {rows.map((trip, index) => (
              <li
                key={trip.id}
                className="grid gap-x-6 gap-y-2 px-4 py-3 animate-row-in sm:grid-cols-[minmax(0,1.4fr)_minmax(0,1fr)_auto] sm:items-center"
                style={{ animationDelay: `${staggerDelay(index)}ms` }}
              >
                <RouteCell from={trip.pickup_summary} to={trip.destination_summary} />
                <span className="text-sm text-navy">
                  {trip.driver
                    ? localizedName(i18n.language, trip.driver.name_en, trip.driver.name_ar)
                    : t('trips.unassigned')}
                </span>
                <TripPhase status={trip.status} confirmation={trip.confirmation_status} />
              </li>
            ))}
          </ul>
        )}
      </div>
    </section>
  )
}

function DashboardSkeleton() {
  return (
    <div aria-hidden="true" className="flex flex-col gap-7">
      <div className="h-[168px] rounded-[22px] bg-[linear-gradient(135deg,var(--color-deep)_0%,var(--color-navy)_55%,var(--color-navy-deep)_100%)] opacity-90" />
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {[0, 1, 2, 3].map((index) => (
          <div key={index} className="h-[96px] rounded-card border border-line bg-white p-4">
            <span className="skeleton block h-3 w-28" />
            <span className="skeleton mt-6 block h-7 w-12" />
          </div>
        ))}
      </div>
      <div className="h-[52px] rounded-card border border-line bg-white" />
    </div>
  )
}
