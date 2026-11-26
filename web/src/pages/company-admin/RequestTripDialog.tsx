import { zodResolver } from '@hookform/resolvers/zod'
import { useMemo, useState } from 'react'
import { useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import { z } from 'zod'
import type { TripRequest } from '../../api/types'
import { useActivePlaces } from '../../api/use-places'
import { useCreateTripRequest } from '../../api/use-trip-requests'
import { DetailDialog } from '../../components/ui/DetailDialog'
import { fieldDescribedBy } from '../../components/ui/described-by'
import { FormField } from '../../components/ui/FormField'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { controlClass, primaryButtonClass } from '../../components/ui/styles'
import { messageForApiError } from '../../lib/api-message'
import { ApiError } from '../../api/errors'
import { cairoInputToIso, isFutureCairoInput, nextSlotInput } from '../../lib/cairo-schedule'
import { localizedName } from '../../lib/names'

type RequestTripDialogProps = {
  open: boolean
  onClose: () => void
  /** When set, the caller continues after a successful create (for example, assigning a driver). */
  onCreated?: (request: TripRequest) => Promise<void> | void
}

type FormValues = {
  pickup: string
  destination: string
  requested_at: string
  notes: string
}

export function RequestTripDialog({ open, onClose, onCreated }: RequestTripDialogProps) {
  const { t, i18n } = useTranslation()
  const places = useActivePlaces(open)
  const create = useCreateTripRequest()
  const [banner, setBanner] = useState<string | null>(null)
  const [created, setCreated] = useState<TripRequest | null>(null)

  const schema = useMemo(
    () =>
      z
        .object({
          pickup: z.string().min(1, t('validation.required')),
          destination: z.string().min(1, t('validation.required')),
          requested_at: z.string().min(1, t('validation.required')),
          notes: z.string().max(1000),
        })
        .superRefine((values, context) => {
          if (values.pickup !== '' && values.pickup === values.destination) {
            context.addIssue({
              code: z.ZodIssueCode.custom,
              path: ['destination'],
              message: t('myTrips.differentPlaces'),
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
    reset,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { pickup: '', destination: '', requested_at: '', notes: '' },
  })

  function close() {
    setCreated(null)
    setBanner(null)
    reset()
    onClose()
  }

  async function onSubmit(values: FormValues) {
    setBanner(null)
    if (!isFutureCairoInput(values.requested_at)) {
      setError('requested_at', { message: t('myTrips.future') })
      return
    }
    const notes = values.notes.trim()
    try {
      const request = await create.mutateAsync({
        pickup: { place_id: values.pickup },
        destination: { place_id: values.destination },
        requested_at: cairoInputToIso(values.requested_at),
        ...(notes ? { notes } : {}),
      })
      if (onCreated) {
        await onCreated(request)
        reset()
        return
      }
      setCreated(request)
      reset()
    } catch (error) {
      setBanner(applyRequestErrors(error, setError, t))
    }
  }

  return (
    <DetailDialog open={open} title={t('myTrips.request')} onClose={close}>
      {created ? (
        <div className="flex flex-col gap-3">
          <p className="text-sm text-ink-muted">{t('myTrips.resultTitle')}</p>
          <StatusBadge status={created.status} />
          {created.auto_approved && created.status === 'approved' ? (
            <p className="text-sm text-ink-muted">{t('myTrips.autoAccepted')}</p>
          ) : null}
          <button type="button" className={primaryButtonClass} onClick={close}>
            {t('common.close')}
          </button>
        </div>
      ) : (
        <form
          className="flex flex-col gap-4"
          onSubmit={(event) => void handleSubmit(onSubmit)(event)}
          noValidate
        >
          {banner ? (
            <p role="alert" className="text-sm text-danger-ink">
              {banner}
            </p>
          ) : null}
          {places.isError ? (
            <p role="alert" className="text-sm text-danger-ink">
              {messageForApiError(places.error, t)}
            </p>
          ) : null}
          <FormField id="trip-pickup" label={t('requests.from')} error={errors.pickup?.message}>
            <select
              id="trip-pickup"
              className={controlClass}
              aria-describedby={fieldDescribedBy('trip-pickup', errors.pickup?.message)}
              disabled={places.isPending}
              {...register('pickup')}
            >
              <option value="">{t('myTrips.choosePlace')}</option>
              {(places.data ?? []).map((place) => (
                <option key={place.id} value={place.id}>
                  {localizedName(i18n.language, place.name_en, place.name_ar)}
                </option>
              ))}
            </select>
          </FormField>
          <FormField
            id="trip-destination"
            label={t('requests.to')}
            error={errors.destination?.message}
          >
            <select
              id="trip-destination"
              className={controlClass}
              aria-describedby={fieldDescribedBy('trip-destination', errors.destination?.message)}
              disabled={places.isPending}
              {...register('destination')}
            >
              <option value="">{t('myTrips.choosePlace')}</option>
              {(places.data ?? []).map((place) => (
                <option key={place.id} value={place.id}>
                  {localizedName(i18n.language, place.name_en, place.name_ar)}
                </option>
              ))}
            </select>
          </FormField>
          <FormField id="trip-when" label={t('requests.when')} error={errors.requested_at?.message}>
            <input
              id="trip-when"
              type="datetime-local"
              className={controlClass}
              min={nextSlotInput()}
              aria-describedby={fieldDescribedBy('trip-when', errors.requested_at?.message)}
              {...register('requested_at')}
              onFocus={(event) => {
                if (event.currentTarget.value === '') {
                  setValue('requested_at', nextSlotInput())
                }
              }}
            />
          </FormField>
          <FormField id="trip-notes" label={t('requests.notes')} error={errors.notes?.message}>
            <textarea
              id="trip-notes"
              className={`${controlClass} h-24 py-2`}
              maxLength={1000}
              aria-describedby={fieldDescribedBy('trip-notes', errors.notes?.message)}
              {...register('notes')}
            />
          </FormField>
          <button
            type="submit"
            className={primaryButtonClass}
            disabled={isSubmitting || places.isPending}
          >
            {isSubmitting ? t('common.loading') : t('myTrips.submit')}
          </button>
        </form>
      )}
    </DetailDialog>
  )
}

function applyRequestErrors(
  error: unknown,
  setError: (name: keyof FormValues, error: { message: string }) => void,
  t: ReturnType<typeof useTranslation>['t'],
): string | null {
  if (!(error instanceof ApiError)) return messageForApiError(error, t)
  const fields: Record<string, keyof FormValues> = {
    pickup: 'pickup',
    'pickup.place_id': 'pickup',
    destination: 'destination',
    'destination.place_id': 'destination',
    requested_at: 'requested_at',
    scheduled_at: 'requested_at',
    notes: 'notes',
  }
  let banner: string | null = error.message
  if (!error.errors) return banner
  for (const [key, messages] of Object.entries(error.errors)) {
    const message = messages[0]
    if (!message) continue
    const field = fields[key]
    if (field) {
      setError(field, { message })
      banner = null
    } else if (key === 'general') {
      banner = message
    }
  }
  return banner
}
