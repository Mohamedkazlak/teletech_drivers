import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { LiveMapDriver, LiveMapState } from '../api/types'
import { useFleetLiveMap } from '../api/use-live-map'
import { PageHeading } from '../components/layout/AppShell'
import { MapView, type MapMarker, type MapMarkerTone } from '../components/map/MapView'
import { StatusBadge } from '../components/ui/StatusBadge'
import { secondaryButtonClass } from '../components/ui/styles'
import { messageForApiError } from '../lib/api-message'
import { formatWhen } from '../lib/format'
import { localizedName } from '../lib/names'

const markerTone: Record<LiveMapState, MapMarkerTone> = {
  available: 'available',
  unavailable: 'unavailable',
  on_trip: 'on_trip',
}

export function LiveMapPage() {
  const { t, i18n } = useTranslation()
  const map = useFleetLiveMap()
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const drivers = map.data?.data ?? []
  const located = drivers.filter((driver) => driver.lat != null && driver.lng != null)
  const missing = drivers.filter((driver) => driver.lat == null || driver.lng == null)
  const selected = drivers.find((driver) => driver.driver.id === selectedId) ?? null
  const markers: MapMarker[] = located.map((driver) => ({
    id: driver.driver.id,
    lat: driver.lat ?? 0,
    lng: driver.lng ?? 0,
    label: driverName(driver, i18n.language),
    tone: markerTone[driver.state],
  }))

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('liveMap.title')}>
        <div className="flex flex-wrap items-center gap-3">
          {map.dataUpdatedAt > 0 ? (
            <p className="text-sm text-ink-muted" aria-live="polite">
              {t('liveMap.updated', {
                time: formatWhen(new Date(map.dataUpdatedAt).toISOString(), i18n.language),
              })}
            </p>
          ) : null}
          <button
            type="button"
            className={secondaryButtonClass}
            onClick={() => {
              void map.refetch()
            }}
          >
            {t('liveMap.refresh')}
          </button>
        </div>
      </PageHeading>
      <p className="text-sm text-ink-muted">{t('liveMap.hint')}</p>
      {map.isPending ? <p role="status">{t('common.loading')}</p> : null}
      {map.isError ? (
        <div className="flex flex-col items-start gap-3">
          <p role="alert" className="text-sm text-danger-ink">
            {messageForApiError(map.error, t)}
          </p>
          <button type="button" className={secondaryButtonClass} onClick={() => void map.refetch()}>
            {t('common.retry')}
          </button>
        </div>
      ) : null}
      {map.data && drivers.length === 0 ? (
        <p className="text-sm text-ink-muted">{t('liveMap.empty')}</p>
      ) : null}
      {map.data ? (
        <div className="grid items-start gap-4 lg:grid-cols-[minmax(0,1fr)_20rem]">
          <div className="overflow-hidden rounded-card border border-line bg-white">
            <MapView
              className="h-80 w-full sm:h-[28rem]"
              markers={markers}
              onSelect={setSelectedId}
            />
          </div>
          <div className="flex flex-col gap-4">
            {selected ? (
              <DriverCard driver={selected} language={i18n.language} />
            ) : (
              <p className="text-sm text-ink-muted">{t('liveMap.select')}</p>
            )}
            {located.length > 0 ? (
              <div>
                <h2 className="text-sm font-semibold text-navy">{t('liveMap.drivers')}</h2>
                <ul className="mt-2 flex flex-col gap-2">
                  {located.map((driver) => {
                    const name = driverName(driver, i18n.language)
                    const selectedDriver = driver.driver.id === selectedId
                    return (
                      <li key={driver.driver.id}>
                        <button
                          type="button"
                          aria-pressed={selectedDriver}
                          className={
                            selectedDriver
                              ? 'h-9 w-full rounded-control bg-deep px-3 text-start text-sm font-semibold text-white'
                              : 'h-9 w-full rounded-control border-[1.5px] border-mid bg-pale px-3 text-start text-sm font-medium text-navy'
                          }
                          onClick={() => setSelectedId(driver.driver.id)}
                        >
                          {t('liveMap.showDriver', { name })}
                        </button>
                      </li>
                    )
                  })}
                </ul>
              </div>
            ) : null}
            {missing.length > 0 ? (
              <div>
                <h2 className="text-sm font-semibold text-navy">{t('liveMap.noFix')}</h2>
                <p className="mt-1 text-sm text-ink-muted">{t('liveMap.noFixList')}</p>
                <ul className="mt-2 list-disc ps-5 text-sm text-navy">
                  {missing.map((driver) => (
                    <li key={driver.driver.id}>{driverName(driver, i18n.language)}</li>
                  ))}
                </ul>
              </div>
            ) : null}
          </div>
        </div>
      ) : null}
    </section>
  )
}

function DriverCard({ driver, language }: { driver: LiveMapDriver; language: string }) {
  const { t } = useTranslation()
  const name = driverName(driver, language)
  const trip = driver.trip
  return (
    <section
      aria-label={t('liveMap.card')}
      className="rounded-card border border-line bg-white p-4"
    >
      <h2 className="text-base font-semibold text-navy">{name}</h2>
      <dl className="mt-3 grid gap-2 text-sm">
        <div>
          <dt className="text-xs font-medium text-ink-muted">{t('driverAdmin.phone')}</dt>
          <dd>{driver.driver.phone || t('common.dash')}</dd>
        </div>
        <div>
          <dt className="text-xs font-medium text-ink-muted">{t('availabilityAdmin.state')}</dt>
          <dd className="mt-1">
            <StatusBadge status={driver.state} />
          </dd>
        </div>
        <div>
          <dt className="text-xs font-medium text-ink-muted">{t('liveMap.trip')}</dt>
          <dd>
            {trip ? (
              <span>
                {t('requests.routeValue', {
                  from: trip.pickup_summary || t('common.dash'),
                  to: trip.destination_summary || t('common.dash'),
                })}
                <span className="mt-1 block">
                  <StatusBadge status={trip.status} />
                </span>
              </span>
            ) : (
              t('liveMap.noTrip')
            )}
          </dd>
        </div>
        <div>
          <dt className="text-xs font-medium text-ink-muted">{t('liveMap.lastSeen')}</dt>
          <dd>{formatWhen(driver.updated_at, language) || t('common.dash')}</dd>
        </div>
      </dl>
    </section>
  )
}

function driverName(driver: LiveMapDriver, language: string): string {
  return localizedName(language, driver.driver.name_en, driver.driver.name_ar)
}
