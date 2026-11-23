import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useCancelTrip, useTrip } from '../../api/use-trips'
import { useDriverLocation } from '../../api/use-live-map'
import { ConfirmDialog } from '../../components/ui/ConfirmDialog'
import { dangerQuietButtonClass, primaryButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { messageForApiError } from '../../lib/api-message'
import {
  canAssignDriver,
  canCancelTrip,
  canReassignDriver,
  isTripInProgress,
} from '../../lib/trip-actions'
import { OwnTripReport } from '../../components/trips/OwnTripReport'
import { TripDetailDialog } from '../company-admin/TripDetailDialog'
import { AssignmentDialog } from './AssignmentDialog'

type FleetTripDetailProps = {
  tripId: string | null
  onClose: () => void
  /** My Trips files the requester's report. The fleet list stays read-only. */
  allowOwnReport?: boolean
  focusReport?: boolean
}

export function FleetTripDetail({
  tripId,
  onClose,
  allowOwnReport = false,
  focusReport = false,
}: FleetTripDetailProps) {
  const { t } = useTranslation()
  const toast = useToast()
  const detail = useTrip(tripId, { pollWhileInProgress: true, poll: allowOwnReport })
  const trip = tripId ? (detail.data ?? null) : null
  const [assignId, setAssignId] = useState<string | null>(null)
  const [excludeDriverId, setExcludeDriverId] = useState<string | null>(null)
  const [cancelOpen, setCancelOpen] = useState(false)
  const [cancelError, setCancelError] = useState<string | null>(null)
  const cancel = useCancelTrip()
  useEffect(() => {
    if (!focusReport || !trip) return
    document.getElementById('post-trip-report')?.scrollIntoView({ block: 'center' })
  }, [focusReport, trip])

  const covered = assignId !== null || cancelOpen
  const inProgress = !covered && trip != null && isTripInProgress(trip.status)
  const location = useDriverLocation(inProgress && trip ? trip.driver_id : null)
  const point = location.data?.data.find((item) => item.lat != null && item.lng != null)
  const driverLocation =
    point && point.lat != null && point.lng != null ? { lat: point.lat, lng: point.lng } : null

  async function confirmCancel() {
    if (!trip) return
    setCancelError(null)
    try {
      await cancel.mutateAsync(trip.id)
      toast(t('drivers.cancelled'), 'success')
      setCancelOpen(false)
    } catch (error) {
      setCancelError(messageForApiError(error, t))
    }
  }

  return (
    <>
      <TripDetailDialog
        trip={covered ? null : trip}
        isLoading={!covered && tripId !== null && detail.isPending}
        error={!covered && tripId && detail.isError ? messageForApiError(detail.error, t) : null}
        onClose={onClose}
        showLive={inProgress}
        driverLocation={driverLocation}
        report={allowOwnReport && trip && !covered ? <OwnTripReport trip={trip} /> : null}
        actions={
          trip && !covered ? (
            <div className="flex flex-wrap gap-2">
              {canAssignDriver(trip.status) || canReassignDriver(trip.status) ? (
                <button
                  type="button"
                  className={primaryButtonClass}
                  onClick={() => {
                    setExcludeDriverId(canReassignDriver(trip.status) ? trip.driver_id : null)
                    setAssignId(trip.id)
                  }}
                >
                  {canReassignDriver(trip.status)
                    ? t('drivers.reassign')
                    : t('drivers.confirmAssign')}
                </button>
              ) : null}
              {canCancelTrip(trip.status) ? (
                <button
                  type="button"
                  className={dangerQuietButtonClass}
                  onClick={() => {
                    setCancelError(null)
                    setCancelOpen(true)
                  }}
                >
                  {t('drivers.cancelTrip')}
                </button>
              ) : null}
            </div>
          ) : null
        }
      />
      <AssignmentDialog
        key={assignId ?? 'assign-closed'}
        tripId={assignId}
        excludeDriverId={excludeDriverId}
        onClose={() => setAssignId(null)}
      />
      <ConfirmDialog
        open={cancelOpen}
        title={t('drivers.cancelTitle')}
        description={t('drivers.cancelMessage')}
        confirmLabel={t('drivers.cancelTrip')}
        cancelLabel={t('common.cancel')}
        tone="danger"
        busy={cancel.isPending}
        onCancel={() => setCancelOpen(false)}
        onConfirm={() => {
          void confirmCancel()
        }}
      >
        {cancelError ? (
          <p role="alert" className="text-sm text-danger">
            {cancelError}
          </p>
        ) : null}
      </ConfirmDialog>
    </>
  )
}
