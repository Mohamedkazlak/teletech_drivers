import type { TFunction } from 'i18next'
import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import type { AdminDashboard } from '../api/types'
import { useAdminDashboard } from '../api/use-dashboard'
import { BarChartCard, type ChartPoint } from '../components/charts/BarChartCard'
import { PageHeading } from '../components/layout/AppShell'
import { secondaryButtonClass } from '../components/ui/styles'
import { messageForApiError } from '../lib/api-message'

export function DashboardPage() {
  const { t } = useTranslation()
  const dashboard = useAdminDashboard()
  const summary = dashboard.data?.data

  return (
    <section className="flex flex-col gap-5">
      <PageHeading title={t('nav.dashboard')} />
      {dashboard.isPending ? <p role="status">{t('common.loading')}</p> : null}
      {dashboard.isError ? (
        <div className="flex flex-col items-start gap-3">
          <p role="alert" className="text-sm text-danger">
            {messageForApiError(dashboard.error, t)}
          </p>
          <button
            type="button"
            className={secondaryButtonClass}
            onClick={() => void dashboard.refetch()}
          >
            {t('common.retry')}
          </button>
        </div>
      ) : null}
      {summary ? (
        <>
          <CardGroup title={t('dashboard.drivers')}>
            <StatCard
              to="/admin/drivers"
              label={t('dashboard.driversTotal')}
              value={summary.drivers.total}
            />
            <StatCard
              to="/admin/attendance"
              label={t('dashboard.driversCheckedIn')}
              value={summary.drivers.checked_in}
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
            />
          </CardGroup>
          <CardGroup title={t('dashboard.employees')}>
            <StatCard
              to="/admin/employees"
              label={t('dashboard.employees')}
              value={summary.employees_total}
            />
          </CardGroup>
          <CardGroup title={t('dashboard.places')}>
            <StatCard
              to="/admin/places"
              label={t('dashboard.places')}
              value={summary.places_total}
            />
          </CardGroup>
          <CardGroup title={t('dashboard.trips')}>
            <StatCard
              to="/admin/trips?stage=unassigned"
              label={t('dashboard.tripsUnassigned')}
              value={summary.trips.unassigned}
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
            />
            <StatCard
              to="/admin/trips?stage=completed&finished_period=day"
              label={t('dashboard.tripsCompletedToday')}
              value={summary.trips.completed_today}
            />
            <StatCard
              to="/admin/trips?stage=completed&finished_period=week"
              label={t('dashboard.tripsCompletedWeek')}
              value={summary.trips.completed_this_week}
            />
          </CardGroup>
          <CardGroup title={t('dashboard.requests')}>
            <StatCard
              to="/admin/trip-requests?status=pending"
              label={t('dashboard.requestsPending')}
              value={summary.requests.pending}
            />
            <StatCard
              to="/admin/trip-requests?status=approved"
              label={t('dashboard.requestsApproved')}
              value={summary.requests.approved}
            />
            <StatCard
              to="/admin/trip-requests?status=rejected"
              label={t('dashboard.requestsRejected')}
              value={summary.requests.rejected}
            />
          </CardGroup>
          <CardGroup title={t('dashboard.unconfirmed')}>
            <StatCard
              to="/admin/trips?unconfirmed=true"
              label={t('dashboard.unconfirmed')}
              value={summary.unconfirmed_trips}
            />
          </CardGroup>
          <BarChartCard title={t('dashboard.chart')} points={tripPoints(summary.trips, t)} />
        </>
      ) : null}
    </section>
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

function CardGroup({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="flex flex-col gap-3">
      <h2 className="text-base font-bold text-navy">{title}</h2>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">{children}</div>
    </section>
  )
}

function StatCard({ to, label, value }: { to: string; label: string; value: number }) {
  return (
    <Link
      to={to}
      className="rounded-card border border-pale bg-white px-4 py-3 text-start hover:border-deep"
    >
      <p className="text-sm text-navy/75">{label}</p>
      <p className="mt-1 text-2xl font-bold text-navy">{value}</p>
    </Link>
  )
}
