import type { TFunction } from 'i18next'
import type { ComponentType, ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import type { AdminDashboard } from '../api/types'
import { useAdminDashboard } from '../api/use-dashboard'
import { RingField } from '../components/brand/BrandMark'
import { BarChartCard, type ChartPoint } from '../components/charts/BarChartCard'
import {
  AlertIcon,
  ArrowEndIcon,
  CarIcon,
  ClipboardIcon,
  PeopleIcon,
  PinIcon,
  RefreshIcon,
  RouteIcon,
} from '../components/icons'
import { PageHeading } from '../components/layout/AppShell'
import CountUp from '../components/reactbits/CountUp'
import { secondaryButtonClass } from '../components/ui/styles'
import { messageForApiError } from '../lib/api-message'

type IconType = ComponentType<{ size?: number; className?: string }>

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
          <CardGroup title={t('dashboard.drivers')} icon={CarIcon}>
            <StatCard
              to="/admin/drivers"
              label={t('dashboard.driversTotal')}
              value={summary.drivers.total}
            />
            <StatCard
              to="/admin/attendance"
              label={t('dashboard.driversCheckedIn')}
              value={summary.drivers.checked_in}
              tone="success"
            />
            <StatCard
              to="/admin/attendance"
              label={t('dashboard.driversCheckedOut')}
              value={summary.drivers.checked_out}
            />
            <StatCard
              to="/admin/attendance"
              label={t('dashboard.driversAbsent')}
              value={summary.drivers.absent}
              tone="warning"
            />
          </CardGroup>
          <CardGroup title={t('dashboard.trips')} icon={RouteIcon}>
            <StatCard
              to="/admin/trips?stage=unassigned"
              label={t('dashboard.tripsUnassigned')}
              value={summary.trips.unassigned}
              tone="warning"
            />
            <StatCard
              to="/admin/trips?stage=assigned"
              label={t('dashboard.tripsAssigned')}
              value={summary.trips.assigned}
            />
            <StatCard
              to="/admin/trips?stage=in_progress"
              label={t('dashboard.tripsInProgress')}
              value={summary.trips.in_progress}
              tone="live"
            />
            <StatCard
              to="/admin/trips?stage=completed&finished_period=day"
              label={t('dashboard.tripsCompletedToday')}
              value={summary.trips.completed_today}
              tone="success"
            />
            <StatCard
              to="/admin/trips?stage=completed&finished_period=week"
              label={t('dashboard.tripsCompletedWeek')}
              value={summary.trips.completed_this_week}
            />
          </CardGroup>
          <div className="grid gap-7 xl:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)]">
            <div className="flex flex-col gap-7">
              <CardGroup title={t('dashboard.requests')} icon={ClipboardIcon} compact>
                <StatCard
                  to="/admin/trip-requests?status=pending"
                  label={t('dashboard.requestsPending')}
                  value={summary.requests.pending}
                  tone="warning"
                />
                <StatCard
                  to="/admin/trip-requests?status=approved"
                  label={t('dashboard.requestsApproved')}
                  value={summary.requests.approved}
                  tone="success"
                />
                <StatCard
                  to="/admin/trip-requests?status=rejected"
                  label={t('dashboard.requestsRejected')}
                  value={summary.requests.rejected}
                  tone="danger"
                />
              </CardGroup>
              <div className="grid gap-7 sm:grid-cols-3">
                <CardGroup title={t('dashboard.employees')} icon={PeopleIcon} single>
                  <StatCard
                    to="/admin/employees"
                    label={t('dashboard.employees')}
                    value={summary.employees_total}
                  />
                </CardGroup>
                <CardGroup title={t('dashboard.places')} icon={PinIcon} single>
                  <StatCard
                    to="/admin/places"
                    label={t('dashboard.places')}
                    value={summary.places_total}
                  />
                </CardGroup>
                <CardGroup title={t('dashboard.unconfirmed')} icon={AlertIcon} single>
                  <StatCard
                    to="/admin/trips?unconfirmed=true"
                    label={t('dashboard.unconfirmed')}
                    value={summary.unconfirmed_trips}
                    tone={summary.unconfirmed_trips > 0 ? 'warning' : undefined}
                  />
                </CardGroup>
              </div>
            </div>
            <BarChartCard title={t('dashboard.chart')} points={tripPoints(summary.trips, t)} />
          </div>
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
  const safeTotal = Math.max(total, checkedIn + checkedOut + absent, 1)
  const segments = [
    { key: 'in', value: checkedIn, label: t('dashboard.driversCheckedIn'), color: '#4fd19a' },
    { key: 'out', value: checkedOut, label: t('dashboard.driversCheckedOut'), color: '#8fb9ff' },
    { key: 'absent', value: absent, label: t('dashboard.driversAbsent'), color: '#f2c26b' },
  ]

  return (
    <section
      aria-label={t('dashboard.attendanceToday')}
      className="relative overflow-hidden rounded-[22px] bg-[linear-gradient(135deg,#0b4da2_0%,#0b1f45_55%,#071533_100%)] p-6 text-white shadow-float animate-rise sm:p-7"
    >
      <RingField />
      <div className="relative grid gap-7 md:grid-cols-[minmax(0,1.6fr)_minmax(0,1fr)] md:items-end">
        <div>
          <p className="text-sm font-medium text-white/70">{t('dashboard.attendanceToday')}</p>
          <p className="mt-2 text-[17px] font-medium text-white/90">
            <span
              aria-hidden="true"
              className="me-1 text-[44px] leading-none font-semibold tracking-[-0.03em] text-white tabular"
            >
              <CountUp to={checkedIn} duration={1.1} mode="roll" trigger="load" />
            </span>
            <span className="sr-only">
              {t('dashboard.checkedInOf', { count: checkedIn, total })}
            </span>
            <span aria-hidden="true" className="text-white/60 tabular">
              / {total}
            </span>
          </p>
          <div
            className="mt-5 flex h-2.5 w-full overflow-hidden rounded-full bg-white/10"
            aria-hidden="true"
          >
            {segments.map((segment, index) => (
              <span
                key={segment.key}
                className="h-full origin-left transition-[width] duration-700 ease-[var(--ease-out)] first:rounded-s-full last:rounded-e-full rtl:origin-right"
                style={{
                  width: `${(segment.value / safeTotal) * 100}%`,
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

function HeroFigure({ label, value, live = false }: { label: string; value: number; live?: boolean }) {
  return (
    <div className="min-w-[8.5rem] flex-1 rounded-[16px] bg-white/[0.08] px-4 py-3.5 shadow-[inset_0_0_0_1px_rgb(255_255_255/0.08)] md:flex-none">
      <p className="flex items-center gap-2 text-[13px] text-white/70">
        {live ? (
          <span aria-hidden="true" className="relative inline-flex h-2 w-2">
            <span className="absolute inset-0 rounded-full bg-[#4fd19a] animate-pulse-ring" />
            <span className="relative h-2 w-2 rounded-full bg-[#4fd19a]" />
          </span>
        ) : null}
        {label}
      </p>
      <p className="mt-1 text-[28px] leading-none font-semibold tracking-[-0.02em] tabular">
        <span aria-hidden="true">
          <CountUp to={value} duration={1} mode="roll" trigger="load" />
        </span>
        <span className="sr-only">{value}</span>
      </p>
    </div>
  )
}

function tripPoints(trips: AdminDashboard['trips'], translate: TFunction): ChartPoint[] {
  return [
    { label: translate('status.unassigned'), value: trips.unassigned },
    { label: translate('status.assigned'), value: trips.assigned },
    { label: translate('status.in_progress'), value: trips.in_progress },
    { label: translate('dashboard.tripsCompletedToday'), value: trips.completed_today },
    { label: translate('dashboard.tripsCompletedWeek'), value: trips.completed_this_week },
  ]
}

function CardGroup({
  title,
  icon: Icon,
  compact = false,
  single = false,
  children,
}: {
  title: string
  icon: IconType
  compact?: boolean
  single?: boolean
  children: ReactNode
}) {
  return (
    <section className="flex flex-col gap-3">
      <h2 className="flex items-center gap-2 text-[15px] font-semibold text-navy">
        <Icon size={18} className="text-deep" />
        {title}
      </h2>
      <div
        className={`grid gap-3 [&>*:nth-child(2)]:[animation-delay:50ms] [&>*:nth-child(3)]:[animation-delay:90ms] [&>*:nth-child(4)]:[animation-delay:120ms] [&>*:nth-child(5)]:[animation-delay:145ms] ${
          single
            ? ''
            : compact
              ? 'sm:grid-cols-3'
              : 'sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-5'
        }`}
      >
        {children}
      </div>
    </section>
  )
}

type Tone = 'success' | 'warning' | 'danger' | 'live'

const toneDot: Record<Tone, string> = {
  success: 'bg-success',
  warning: 'bg-warning',
  danger: 'bg-danger',
  live: 'bg-signal',
}

function StatCard({
  to,
  label,
  value,
  tone,
}: {
  to: string
  label: string
  value: number
  tone?: Tone
}) {
  return (
    <Link
      to={to}
      className="group relative flex min-h-[104px] flex-col justify-between overflow-hidden rounded-card border border-line bg-white px-4 py-3.5 text-start transition-[border-color,box-shadow,transform] duration-200 ease-[var(--ease-out)] animate-rise hover:-translate-y-0.5 hover:border-deep/35 active:translate-y-0 active:scale-[0.99]"
    >
      <p className="flex items-center gap-2 text-[13px] leading-snug text-ink-muted">
        {tone ? (
          <span aria-hidden="true" className={`h-1.5 w-1.5 shrink-0 rounded-full ${toneDot[tone]}`} />
        ) : null}
        {label}
      </p>
      <div className="mt-2 flex items-end justify-between gap-2">
        <p className="text-[30px] leading-none font-semibold tracking-[-0.02em] text-navy tabular">
          <span aria-hidden="true">
            <CountUp to={value} duration={1} mode="roll" trigger="load" />
          </span>
          <span className="sr-only">{value}</span>
        </p>
        <ArrowEndIcon
          size={18}
          className="text-deep opacity-0 transition-[opacity,transform] duration-200 ease-[var(--ease-out)] group-hover:translate-x-0.5 group-hover:opacity-100 group-focus-visible:opacity-100 rtl:group-hover:-translate-x-0.5"
        />
      </div>
    </Link>
  )
}

function DashboardSkeleton() {
  return (
    <div aria-hidden="true" className="flex flex-col gap-7">
      <div className="h-[168px] rounded-[22px] bg-[linear-gradient(135deg,#0b4da2_0%,#0b1f45_55%,#071533_100%)] opacity-90" />
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-5">
        {[0, 1, 2, 3, 4].map((index) => (
          <div key={index} className="h-[104px] rounded-card border border-line bg-white p-4">
            <span className="skeleton block h-3 w-24" />
            <span className="skeleton mt-6 block h-7 w-12" />
          </div>
        ))}
      </div>
    </div>
  )
}
