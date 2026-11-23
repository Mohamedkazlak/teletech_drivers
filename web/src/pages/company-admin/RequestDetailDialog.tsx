import { useTranslation } from 'react-i18next'
import type { TripRequest } from '../../api/types'
import { BranchText } from '../../components/ui/BranchText'
import { DetailDialog } from '../../components/ui/DetailDialog'
import { DetailList } from '../../components/ui/DetailList'
import { MapView, type MapMarker } from '../../components/map/MapView'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { dangerQuietButtonClass, primaryButtonClass } from '../../components/ui/styles'
import { formatWhen } from '../../lib/format'
import { localizedName } from '../../lib/names'

type RequestDetailDialogProps = {
  request: TripRequest | null
  isLoading: boolean
  error: string | null
  onClose: () => void
  onApprove?: (id: string) => void
  onReject?: (id: string) => void
}

export function RequestDetailDialog({
  request,
  isLoading,
  error,
  onClose,
  onApprove,
  onReject,
}: RequestDetailDialogProps) {
  const { t, i18n } = useTranslation()
  const open = request !== null || isLoading || error !== null
  const markers = request ? placeMarkers(request) : []
  const name = request
    ? localizedName(i18n.language, request.employee_name_en, request.employee_name_ar)
    : ''

  return (
    <DetailDialog open={open} title={t('requests.detailTitle')} onClose={onClose}>
      {isLoading ? <p role="status">{t('common.loading')}</p> : null}
      {error ? (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      ) : null}
      {request ? (
        <div className="flex flex-col gap-4">
          <div className="flex flex-wrap items-center gap-2">
            <p className="text-base font-medium text-navy">{name || t('common.dash')}</p>
            <StatusBadge status={request.status} />
          </div>
          <DetailList
            items={[
              { label: t('requests.phone'), value: request.employee_phone || t('common.dash') },
              {
                label: t('profile.branch'),
                value: <BranchText value={request.employee_branch} />,
              },
              { label: t('requests.from'), value: request.pickup.name },
              { label: t('requests.to'), value: request.destination.name },
              {
                label: t('requests.when'),
                value: formatWhen(request.requested_at, i18n.language),
              },
              { label: t('requests.notes'), value: request.notes || t('common.dash') },
              {
                label: t('requests.reason'),
                value: request.rejection_reason || t('common.dash'),
              },
            ]}
          />
          {markers.length > 0 ? (
            <div className="overflow-hidden rounded-control border border-pale">
              <MapView markers={markers} className="h-64 w-full" />
            </div>
          ) : null}
          {request.status === 'pending' && onApprove && onReject ? (
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                className={primaryButtonClass}
                onClick={() => onApprove(request.id)}
              >
                {t('requests.approve')}
              </button>
              <button
                type="button"
                className={dangerQuietButtonClass}
                onClick={() => onReject(request.id)}
              >
                {t('requests.reject')}
              </button>
            </div>
          ) : null}
        </div>
      ) : null}
    </DetailDialog>
  )
}

function placeMarkers(request: TripRequest): MapMarker[] {
  const markers: MapMarker[] = []
  if (request.pickup.lat != null && request.pickup.lng != null) {
    markers.push({
      id: 'pickup',
      lat: request.pickup.lat,
      lng: request.pickup.lng,
      label: request.pickup.name,
    })
  }
  if (request.destination.lat != null && request.destination.lng != null) {
    markers.push({
      id: 'destination',
      lat: request.destination.lat,
      lng: request.destination.lng,
      label: request.destination.name,
    })
  }
  return markers
}
