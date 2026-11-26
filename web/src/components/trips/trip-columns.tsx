import type { TFunction } from 'i18next'
import type { ReactNode } from 'react'
import type { TripSummary } from '../../api/types'
import { formatDateTime } from '../../lib/format'
import { localizedName } from '../../lib/names'
import type { Column } from '../ui/DataTable'
import { StatusBadge } from '../ui/StatusBadge'
import { RouteCell } from './RouteCell'
import { TripPhase } from './TripPhase'

type TripColumnOptions<T extends TripSummary> = {
  /** Drivers admin adds the passengers after the route. */
  people?: (trip: T) => string
  /** Replaces the default phase cell (e.g. My trips shows request tracking first). */
  phase?: (trip: T) => ReactNode
  /** Second line under the scheduled time (e.g. actual start – finish). */
  whenDetail?: (trip: T) => ReactNode
  actions: (trip: T) => ReactNode
}

/** One column order for every trip table: When · Route · (People) · Driver · Phase · Actions. */
export function tripColumns<T extends TripSummary>(
  t: TFunction,
  language: string,
  options: TripColumnOptions<T>,
): Column<T>[] {
  const columns: Column<T>[] = [
    {
      id: 'when',
      header: t('trips.when'),
      sortValue: (trip) => trip.scheduled_at,
      mobile: 'title',
      accessor: (trip) => (
        <span className="block whitespace-nowrap tabular">
          {formatDateTime(trip.scheduled_at, language)}
          {options.whenDetail ? (
            <span className="mt-1 block text-xs font-normal text-ink-muted">
              {options.whenDetail(trip)}
            </span>
          ) : null}
        </span>
      ),
    },
    {
      id: 'route',
      header: t('requests.route'),
      accessor: (trip) => <RouteCell from={trip.pickup_summary} to={trip.destination_summary} />,
    },
  ]
  if (options.people) {
    const people = options.people
    columns.push({ id: 'people', header: t('trips.people'), accessor: (trip) => people(trip) })
  }
  columns.push(
    {
      id: 'driver',
      header: t('trips.driver'),
      accessor: (trip) =>
        trip.driver ? (
          localizedName(language, trip.driver.name_en, trip.driver.name_ar)
        ) : (
          <span className="text-ink-muted">{t('trips.unassigned')}</span>
        ),
    },
    {
      id: 'phase',
      header: t('trips.phase'),
      accessor: (trip) =>
        options.phase ? (
          options.phase(trip)
        ) : (
          <span className="inline-flex flex-wrap items-center gap-2">
            <TripPhase status={trip.status} confirmation={trip.confirmation_status} />
            {trip.confirmation_status === 'unconfirmed' ? (
              <StatusBadge status="unconfirmed" />
            ) : null}
          </span>
        ),
    },
    {
      id: 'actions',
      header: t('common.actions'),
      isActions: true,
      accessor: (trip) => options.actions(trip),
    },
  )
  return columns
}
