import { type ReactNode, useMemo } from 'react'
import { useTranslation } from 'react-i18next'
import type { TripReport, TripSummary } from '../../api/types'
import { useTripReport } from '../../api/use-trips'
import { BranchText } from '../../components/ui/BranchText'
import { DetailDialog } from '../../components/ui/DetailDialog'
import { DetailList } from '../../components/ui/DetailList'
import { MapView, type MapMarker, type MapPath } from '../../components/map/MapView'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { RequestTrackingPanel } from '../../components/trips/RequestTrackingPanel'
import { trackingChipStatus } from '../../lib/request-tracking'
import { messageForApiError } from '../../lib/api-message'
import { formatDistanceKm, formatDuration, formatWhen } from '../../lib/format'
import { localizedName } from '../../lib/names'
import { isTripInProgress } from '../../lib/trip-actions'
import { tripStage } from '../../lib/trip-stage'

type TripDetailDialogProps = {
  trip: TripSummary | null
  isLoading: boolean
  error: string | null
  onClose: () => void
  actions?: ReactNode
  report?: ReactNode
  showLive?: boolean
  driverLocation?: { lat: number; lng: number } | null
}

export function TripDetailDialog({
  trip,
  isLoading,
  error,
  onClose,
  actions,
  report,
  showLive = false,
  driverLocation = null,
}: TripDetailDialogProps) {
  const { t, i18n } = useTranslation()
  const open = trip !== null || isLoading || error !== null
  const showReport = trip != null && shouldShowReport(trip)
  const reportQuery = useTripReport(showReport && trip ? trip.id : null)
  const markers = useMemo(() => (trip ? tripMarkers(trip) : []), [trip])
  const drivenPath = useMemo(() => routePath(reportQuery.data), [reportQuery.data])
  const liveMarkers = useMemo(() => {
    if (!showLive || !trip) return []
    const next = [...tripMarkers(trip)]
    if (driverLocation) {
      const name = trip.driver
        ? localizedName(i18n.language, trip.driver.name_en, trip.driver.name_ar)
        : t('trips.driver')
      next.push({
        id: 'driver',
        lat: driverLocation.lat,
        lng: driverLocation.lng,
        label: name || t('trips.driver'),
        tone: 'driver',
      })
    }
    return next
  }, [driverLocation, i18n.language, showLive, t, trip])

  return (
    <DetailDialog open={open} title={t('trips.detailTitle')} onClose={onClose}>
      {isLoading ? <p role="status">{t('common.loading')}</p> : null}
      {error ? (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      ) : null}
      {trip ? (
        <div className="flex flex-col gap-5">
          <div className="flex flex-wrap items-center gap-2">
            <StatusBadge status={trip.status} />
            <StatusBadge status={tripStage(trip)} />
            {trip.confirmation_status === 'unconfirmed' ? (
              <StatusBadge status="unconfirmed" />
            ) : null}
            {trip.tracking ? (
              <StatusBadge status={trackingChipStatus(trip.tracking.stage)} />
            ) : null}
          </div>
          {trip.tracking ? <RequestTrackingPanel tracking={trip.tracking} /> : null}
          <DetailList
            items={[
              {
                label: t('trips.driver'),
                value: trip.driver
                  ? localizedName(i18n.language, trip.driver.name_en, trip.driver.name_ar)
                  : t('trips.unassigned'),
              },
              {
                label: t('requests.from'),
                value: trip.pickup_summary || t('common.dash'),
              },
              {
                label: t('requests.to'),
                value: trip.destination_summary || t('common.dash'),
              },
              {
                label: t('trips.scheduled'),
                value: formatWhen(trip.scheduled_at, i18n.language),
              },
              {
                label: t('trips.started'),
                value: formatWhen(trip.going_started_at, i18n.language) || t('common.dash'),
              },
              {
                label: t('trips.finished'),
                value: formatWhen(trip.finished_at, i18n.language) || t('common.dash'),
              },
            ]}
          />
          <section>
            <h3 className="text-sm font-semibold text-navy">{t('trips.people')}</h3>
            {trip.passengers.length === 0 ? (
              <p className="mt-2 text-sm text-ink-muted">{t('common.empty')}</p>
            ) : (
              <ul className="mt-2 flex flex-col gap-3">
                {trip.passengers.map((passenger) => (
                  <li key={passenger.request_id} className="rounded-control border border-line p-3">
                    <p className="font-medium text-navy">
                      {localizedName(i18n.language, passenger.name_en, passenger.name_ar) ||
                        t('common.dash')}
                    </p>
                    <p className="text-sm text-ink-muted">
                      {passenger.phone || t('common.dash')}
                      {' · '}
                      <BranchText value={passenger.branch} />
                    </p>
                    <p className="text-sm text-ink-muted">
                      {t('requests.routeValue', {
                        from: passenger.pickup.name,
                        to: passenger.destination.name,
                      })}
                    </p>
                  </li>
                ))}
              </ul>
            )}
          </section>
          {showLive ? (
            <section aria-label={t('drivers.live')}>
              <h3 className="text-sm font-semibold text-navy">{t('drivers.live')}</h3>
              <p className="mt-1 text-sm text-ink-muted">{t(`status.${trip.status}`)}</p>
              {driverLocation ? null : (
                <p className="mt-1 text-sm text-ink-muted">{t('drivers.waitingLocation')}</p>
              )}
              {liveMarkers.length > 0 ? (
                <div className="mt-3 overflow-hidden rounded-control border border-line">
                  <MapView markers={liveMarkers} className="h-64 w-full" />
                </div>
              ) : null}
            </section>
          ) : null}
          {showReport ? (
            <section>
              <h3 className="text-sm font-semibold text-navy">{t('trips.report')}</h3>
              {reportQuery.isPending ? (
                <p role="status" className="mt-2 text-sm text-ink-muted">
                  {t('common.loading')}
                </p>
              ) : null}
              {reportQuery.isError ? (
                <p role="alert" className="mt-2 text-sm text-danger">
                  {messageForApiError(reportQuery.error, t)}
                </p>
              ) : null}
              {reportQuery.data ? (
                <div className="mt-2">
                  <DetailList
                    items={[
                      {
                        label: t('trips.start'),
                        value:
                          formatWhen(reportQuery.data.start, i18n.language) || t('common.dash'),
                      },
                      {
                        label: t('trips.finish'),
                        value:
                          formatWhen(reportQuery.data.finish, i18n.language) || t('common.dash'),
                      },
                      {
                        label: t('trips.duration'),
                        value:
                          reportQuery.data.total_duration_seconds == null
                            ? t('common.dash')
                            : formatDuration(reportQuery.data.total_duration_seconds, t),
                      },
                      {
                        label: t('trips.kmGoing'),
                        value: km(
                          reportQuery.data.going_distance_km,
                          i18n.language,
                          t('common.dash'),
                          t,
                        ),
                      },
                      {
                        label: t('trips.kmBack'),
                        value: km(
                          reportQuery.data.return_distance_km,
                          i18n.language,
                          t('common.dash'),
                          t,
                        ),
                      },
                      {
                        label: t('trips.kmTotal'),
                        value: km(
                          reportQuery.data.total_distance_km,
                          i18n.language,
                          t('common.dash'),
                          t,
                        ),
                      },
                      ...confirmationItems(trip, t),
                    ]}
                  />
                </div>
              ) : null}
              {drivenPath ? (
                <div className="mt-3 overflow-hidden rounded-control border border-line">
                  <p className="px-3 py-2 text-xs text-ink-muted">{t('trips.drivenRoute')}</p>
                  <MapView markers={markers} paths={[drivenPath]} className="h-64 w-full" />
                </div>
              ) : markers.length > 0 ? (
                <div className="mt-3 overflow-hidden rounded-control border border-line">
                  <p className="px-3 py-2 text-xs text-ink-muted">{t('trips.pinMap')}</p>
                  <MapView markers={markers} className="h-64 w-full" />
                </div>
              ) : null}
            </section>
          ) : null}
          {report}
          {actions}
        </div>
      ) : null}
    </DetailDialog>
  )
}

function shouldShowReport(trip: TripSummary): boolean {
  return (
    trip.status === 'completed' ||
    isTripInProgress(trip.status) ||
    trip.going_started_at != null ||
    trip.finished_at != null
  )
}

function km(
  value: number | null,
  language: string,
  empty: string,
  translate: (key: string, options: { value: string }) => string,
): string {
  if (value == null) return empty
  return translate('format.kilometers', { value: formatDistanceKm(value, language) })
}

function confirmationItems(
  trip: TripSummary,
  t: (key: string) => string,
): Array<{ label: string; value: string }> {
  if (
    trip.confirmation_status == null &&
    trip.driver_showed_up == null &&
    !trip.confirmation_note
  ) {
    return []
  }
  return [
    {
      label: t('drivers.showedUp'),
      value:
        trip.driver_showed_up == null
          ? t('common.dash')
          : trip.driver_showed_up
            ? t('common.yes')
            : t('common.no'),
    },
    {
      label: t('drivers.confirmationNote'),
      value: trip.confirmation_note || t('common.dash'),
    },
  ]
}

function routePath(report: TripReport | undefined): MapPath | null {
  if (!report || report.driven_route.length === 0) return null
  return {
    id: 'driven',
    points: report.driven_route.map((point) => ({ lat: point.lat, lng: point.lng })),
  }
}

function tripMarkers(trip: TripSummary): MapMarker[] {
  const markers: MapMarker[] = []
  trip.passengers.forEach((passenger, index) => {
    if (passenger.pickup.lat != null && passenger.pickup.lng != null) {
      markers.push({
        id: `pickup-${index}`,
        lat: passenger.pickup.lat,
        lng: passenger.pickup.lng,
        label: passenger.pickup.name,
      })
    }
    if (passenger.destination.lat != null && passenger.destination.lng != null) {
      markers.push({
        id: `destination-${index}`,
        lat: passenger.destination.lat,
        lng: passenger.destination.lng,
        label: passenger.destination.name,
      })
    }
  })
  return markers
}
