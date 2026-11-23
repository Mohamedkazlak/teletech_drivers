import { zodResolver } from '@hookform/resolvers/zod'
import { useMemo, useState } from 'react'
import { useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import { z } from 'zod'
import { ApiError } from '../../api/errors'
import type { CreatePlaceBody } from '../../api/places'
import type { Place } from '../../api/types'
import { useCreatePlace, useUpdatePlace } from '../../api/use-places'
import { MapView, type MapMarker } from '../../components/map/MapView'
import { DetailDialog } from '../../components/ui/DetailDialog'
import { DetailList } from '../../components/ui/DetailList'
import { fieldDescribedBy } from '../../components/ui/described-by'
import { FormField } from '../../components/ui/FormField'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { controlClass, primaryButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { messageForApiError } from '../../lib/api-message'
import { localizedName } from '../../lib/names'
import { changedPlaceFields } from './place-patch'

type PlaceDialogsProps = {
  viewing: Place | null
  editing: Place | null
  creating?: boolean
  onClose: () => void
}

type FormValues = {
  name_en: string
  name_ar: string
  address: string
  latitude: string
  longitude: string
  is_headquarters: boolean
  is_active: boolean
}

export function PlaceDialogs({ viewing, editing, creating = false, onClose }: PlaceDialogsProps) {
  const { t, i18n } = useTranslation()
  const place = editing ?? viewing
  const title = creating ? t('places.add') : editing ? t('places.edit') : t('places.detailTitle')
  return (
    <DetailDialog open={creating || place !== null} title={title} onClose={onClose}>
      {viewing && !editing && !creating ? (
        <PlaceView place={viewing} language={i18n.language} />
      ) : null}
      {creating || editing ? (
        <PlaceForm
          key={creating ? 'new' : editing?.id}
          place={creating ? null : editing}
          onClose={onClose}
        />
      ) : null}
    </DetailDialog>
  )
}

function PlaceView({ place, language }: { place: Place; language: string }) {
  const { t } = useTranslation()
  const markers = markersFor(place)
  return (
    <div className="flex flex-col gap-4">
      <DetailList
        items={[
          { label: t('profile.nameEn'), value: place.name_en },
          { label: t('profile.nameAr'), value: place.name_ar },
          { label: t('places.address'), value: place.address || t('common.dash') },
          {
            label: t('places.headquarters'),
            value: place.is_headquarters ? t('places.headquarters') : t('common.dash'),
          },
          {
            label: t('places.active'),
            value: <StatusBadge status={place.is_active ? 'active' : 'inactive'} />,
          },
        ]}
      />
      <p className="text-sm text-navy/75">
        {localizedName(language, place.name_en, place.name_ar)}
      </p>
      {markers.length > 0 ? (
        <div className="overflow-hidden rounded-control border border-pale">
          <MapView markers={markers} className="h-64 w-full" />
        </div>
      ) : null}
    </div>
  )
}

function PlaceForm({ place, onClose }: { place: Place | null; onClose: () => void }) {
  const { t } = useTranslation()
  const toast = useToast()
  const update = useUpdatePlace()
  const create = useCreatePlace()
  const [banner, setBanner] = useState<string | null>(null)

  const schema = useMemo(
    () =>
      z
        .object({
          name_en: z.string().trim().min(1, t('validation.required')).max(255),
          name_ar: z.string().trim().min(1, t('validation.required')).max(255),
          address: z.string().trim().min(1, t('validation.required')).max(500),
          latitude: z.string(),
          longitude: z.string(),
          is_headquarters: z.boolean(),
          is_active: z.boolean(),
        })
        .superRefine((values, context) => {
          const lat = parseCoord(values.latitude)
          const lng = parseCoord(values.longitude)
          const latEmpty = values.latitude.trim() === ''
          const lngEmpty = values.longitude.trim() === ''
          if (latEmpty !== lngEmpty || lat === 'invalid' || lng === 'invalid') {
            context.addIssue({
              code: z.ZodIssueCode.custom,
              path: ['latitude'],
              message: t('places.coordinatePair'),
            })
          }
          if (typeof lat === 'number' && (lat < -90 || lat > 90)) {
            context.addIssue({
              code: z.ZodIssueCode.custom,
              path: ['latitude'],
              message: t('places.coordinatePair'),
            })
          }
          if (typeof lng === 'number' && (lng < -180 || lng > 180)) {
            context.addIssue({
              code: z.ZodIssueCode.custom,
              path: ['longitude'],
              message: t('places.coordinatePair'),
            })
          }
        }),
    [t],
  )

  const {
    register,
    handleSubmit,
    setError,
    setValue,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name_en: place?.name_en ?? '',
      name_ar: place?.name_ar ?? '',
      address: place?.address ?? '',
      latitude: place?.latitude == null ? '' : String(place.latitude),
      longitude: place?.longitude == null ? '' : String(place.longitude),
      is_headquarters: place?.is_headquarters ?? false,
      is_active: place?.is_active ?? true,
    },
  })

  const [coords, setCoords] = useState({
    latitude: place?.latitude == null ? '' : String(place.latitude),
    longitude: place?.longitude == null ? '' : String(place.longitude),
  })
  const lat = parseCoord(coords.latitude)
  const lng = parseCoord(coords.longitude)
  const markers: MapMarker[] =
    typeof lat === 'number' && typeof lng === 'number'
      ? [{ id: 'place', lat, lng, label: place?.name_en || t('places.name') }]
      : []
  const latitudeField = register('latitude')
  const longitudeField = register('longitude')

  async function onSubmit(values: FormValues) {
    setBanner(null)
    const parsedLat = parseCoord(values.latitude)
    const parsedLng = parseCoord(values.longitude)
    const draft = {
      name_en: values.name_en.trim(),
      name_ar: values.name_ar.trim(),
      address: values.address,
      latitude: typeof parsedLat === 'number' ? parsedLat : null,
      longitude: typeof parsedLng === 'number' ? parsedLng : null,
      is_headquarters: values.is_headquarters,
      is_active: values.is_active,
    }
    try {
      if (!place) {
        await create.mutateAsync(createPlaceBody(draft))
        toast(t('places.created'), 'success')
        onClose()
        return
      }
      const body = changedPlaceFields(place, draft)
      if (Object.keys(body).length === 0) {
        onClose()
        return
      }
      await update.mutateAsync({ id: place.id, body })
      toast(t('places.saved'), 'success')
      onClose()
    } catch (error) {
      setBanner(applyPlaceErrors(error, setError, t))
    }
  }

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={(event) => void handleSubmit(onSubmit)(event)}
      noValidate
    >
      {banner ? (
        <p role="alert" className="text-sm text-danger">
          {banner}
        </p>
      ) : null}
      <FormField id="place-name-en" label={t('profile.nameEn')} error={errors.name_en?.message}>
        <input
          id="place-name-en"
          className={controlClass}
          aria-describedby={fieldDescribedBy('place-name-en', errors.name_en?.message)}
          {...register('name_en')}
        />
      </FormField>
      <FormField id="place-name-ar" label={t('profile.nameAr')} error={errors.name_ar?.message}>
        <input
          id="place-name-ar"
          className={controlClass}
          aria-describedby={fieldDescribedBy('place-name-ar', errors.name_ar?.message)}
          {...register('name_ar')}
        />
      </FormField>
      <FormField id="place-address" label={t('places.address')} error={errors.address?.message}>
        <input
          id="place-address"
          className={controlClass}
          aria-describedby={fieldDescribedBy('place-address', errors.address?.message)}
          {...register('address')}
        />
      </FormField>
      <div className="grid gap-4 sm:grid-cols-2">
        <FormField
          id="place-latitude"
          label={t('places.latitude')}
          error={errors.latitude?.message}
        >
          <input
            id="place-latitude"
            className={controlClass}
            inputMode="decimal"
            aria-describedby={fieldDescribedBy('place-latitude', errors.latitude?.message)}
            {...latitudeField}
            onChange={(event) => {
              void latitudeField.onChange(event)
              setCoords((current) => ({ ...current, latitude: event.target.value }))
            }}
          />
        </FormField>
        <FormField
          id="place-longitude"
          label={t('places.longitude')}
          error={errors.longitude?.message}
        >
          <input
            id="place-longitude"
            className={controlClass}
            inputMode="decimal"
            aria-describedby={fieldDescribedBy('place-longitude', errors.longitude?.message)}
            {...longitudeField}
            onChange={(event) => {
              void longitudeField.onChange(event)
              setCoords((current) => ({ ...current, longitude: event.target.value }))
            }}
          />
        </FormField>
      </div>
      <p className="text-xs text-navy/60">{t('places.pickHint')}</p>
      <div className="overflow-hidden rounded-control border border-pale">
        <MapView
          className="h-64 w-full"
          center={markers[0] ? [markers[0].lat, markers[0].lng] : undefined}
          markers={markers}
          onPick={(nextLat, nextLng) => {
            const latitude = nextLat.toFixed(6)
            const longitude = nextLng.toFixed(6)
            setValue('latitude', latitude, { shouldDirty: true })
            setValue('longitude', longitude, { shouldDirty: true })
            setCoords({ latitude, longitude })
          }}
        />
      </div>
      <label className="inline-flex items-center gap-2 text-sm text-navy">
        <input type="checkbox" {...register('is_headquarters')} />
        {t('places.headquarters')}
      </label>
      <label className="inline-flex items-center gap-2 text-sm text-navy">
        <input type="checkbox" {...register('is_active')} />
        {t('places.active')}
      </label>
      <button type="submit" className={primaryButtonClass} disabled={isSubmitting}>
        {isSubmitting ? t('common.loading') : t('common.save')}
      </button>
    </form>
  )
}

function createPlaceBody(draft: {
  name_en: string
  name_ar: string
  address: string
  latitude: number | null
  longitude: number | null
  is_headquarters: boolean
  is_active: boolean
}): CreatePlaceBody {
  const body: CreatePlaceBody = {
    name_en: draft.name_en,
    name_ar: draft.name_ar,
    address: draft.address.trim(),
    is_headquarters: draft.is_headquarters,
    is_active: draft.is_active,
  }
  if (draft.latitude != null && draft.longitude != null) {
    body.latitude = draft.latitude
    body.longitude = draft.longitude
  }
  return body
}

function markersFor(place: Place): MapMarker[] {
  if (place.latitude == null || place.longitude == null) return []
  return [{ id: place.id, lat: place.latitude, lng: place.longitude, label: place.name_en }]
}

function parseCoord(value: string): number | null | 'invalid' {
  const trimmed = value.trim()
  if (trimmed === '') return null
  const parsed = Number(trimmed)
  if (!Number.isFinite(parsed)) return 'invalid'
  return parsed
}

function applyPlaceErrors(
  error: unknown,
  setError: (name: keyof FormValues, error: { message: string }) => void,
  t: ReturnType<typeof useTranslation>['t'],
): string | null {
  if (!(error instanceof ApiError)) return messageForApiError(error, t)
  const fields: Array<keyof FormValues> = [
    'name_en',
    'name_ar',
    'address',
    'latitude',
    'longitude',
    'is_headquarters',
    'is_active',
  ]
  let banner: string | null = error.message
  if (!error.errors) return banner
  for (const [key, messages] of Object.entries(error.errors)) {
    const message = messages[0]
    if (!message) continue
    if (fields.includes(key as keyof FormValues)) {
      setError(key as keyof FormValues, { message })
      banner = null
    } else if (key === 'general') {
      banner = message
    }
  }
  return banner
}
