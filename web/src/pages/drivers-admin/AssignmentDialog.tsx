import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { DriverRecommendation } from '../../api/types'
import { useAssignTrip, useDriverRecommendations } from '../../api/use-trips'
import { DetailDialog } from '../../components/ui/DetailDialog'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { primaryButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { messageForApiError } from '../../lib/api-message'
import { localizedName } from '../../lib/names'
import { orderedRecommendations } from '../../lib/recommendations'

type AssignmentDialogProps = {
  tripId: string | null
  excludeDriverId?: string | null
  onClose: () => void
}

export function AssignmentDialog({
  tripId,
  excludeDriverId = null,
  onClose,
}: AssignmentDialogProps) {
  const { t, i18n } = useTranslation()
  const toast = useToast()
  const recommendations = useDriverRecommendations(tripId)
  const assign = useAssignTrip()
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const groups = orderedRecommendations(recommendations.data?.data ?? [], excludeDriverId)
  const empty = groups.recommended.length === 0 && groups.others.length === 0

  async function confirm() {
    if (!tripId || !selectedId) return
    setError(null)
    try {
      await assign.mutateAsync({ tripId, driverId: selectedId })
      toast(t('drivers.assigned'), 'success')
      onClose()
    } catch (caught) {
      setError(messageForApiError(caught, t))
    }
  }

  return (
    <DetailDialog open={tripId !== null} title={t('drivers.assignTitle')} onClose={onClose}>
      {recommendations.isPending ? <p role="status">{t('common.loading')}</p> : null}
      {recommendations.isError ? (
        <p role="alert" className="text-sm text-danger">
          {messageForApiError(recommendations.error, t)}
        </p>
      ) : null}
      {recommendations.isSuccess && empty ? (
        <p className="text-sm text-navy/75">{t('drivers.noDrivers')}</p>
      ) : null}
      {recommendations.isSuccess && !empty ? (
        <div
          role="radiogroup"
          aria-label={t('drivers.assignTitle')}
          className="flex flex-col gap-4"
        >
          <DriverGroup
            title={t('drivers.recommended')}
            items={groups.recommended}
            language={i18n.language}
            selectedId={selectedId}
            onSelect={setSelectedId}
          />
          <DriverGroup
            title={t('drivers.others')}
            items={groups.others}
            language={i18n.language}
            selectedId={selectedId}
            onSelect={setSelectedId}
          />
        </div>
      ) : null}
      {error ? (
        <p role="alert" className="mt-4 text-sm text-danger">
          {error}
        </p>
      ) : null}
      <button
        type="button"
        className={`${primaryButtonClass} mt-4`}
        disabled={!selectedId || assign.isPending}
        onClick={() => {
          void confirm()
        }}
      >
        {assign.isPending ? t('common.loading') : t('drivers.confirmAssign')}
      </button>
    </DetailDialog>
  )
}

function DriverGroup({
  title,
  items,
  language,
  selectedId,
  onSelect,
}: {
  title: string
  items: DriverRecommendation[]
  language: string
  selectedId: string | null
  onSelect: (id: string) => void
}) {
  const { t } = useTranslation()
  if (items.length === 0) return null
  return (
    <section>
      <h3 className="text-sm font-bold text-navy">{title}</h3>
      <ul className="mt-2 flex flex-col gap-2">
        {items.map((item) => {
          const name =
            localizedName(language, item.driver.name_en, item.driver.name_ar) || item.driver.id
          return (
            <li key={item.driver.id}>
              <label
                className={`flex items-start gap-3 rounded-control border border-pale p-3 ${item.is_unavailable ? 'opacity-60' : ''}`}
              >
                <input
                  type="radio"
                  name="assignment-driver"
                  value={item.driver.id}
                  className="mt-1"
                  checked={selectedId === item.driver.id}
                  disabled={item.is_unavailable}
                  onChange={() => onSelect(item.driver.id)}
                />
                <span className="flex min-w-0 flex-col gap-1">
                  <span className="font-medium text-navy">{name}</span>
                  {/* distance_from_hq is not on DriverRecommendation; it is not shown. */}
                  <span className="flex flex-wrap items-center gap-2 text-sm text-navy/75">
                    <StatusBadge status={item.is_unavailable ? 'unavailable' : 'available'} />
                    <span>
                      {item.has_favorite_match ? t('drivers.favorite') : t('drivers.noFavorite')}
                    </span>
                    <span>{t('drivers.tripsThisWeek', { count: item.trips_this_week })}</span>
                    {item.has_conflict ? <span>{t('drivers.conflict')}</span> : null}
                    {item.is_on_active_trip ? <span>{t('drivers.onTrip')}</span> : null}
                  </span>
                </span>
              </label>
            </li>
          )
        })}
      </ul>
    </section>
  )
}
