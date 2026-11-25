import { zodResolver } from '@hookform/resolvers/zod'
import { useMemo, useState, type ChangeEvent } from 'react'
import { useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import { z } from 'zod'
import { useActivePlaces } from '../../api/use-places'
import { useCreateDriver, useUpdateDriver } from '../../api/use-drivers'
import type { Driver } from '../../api/types'
import { DetailDialog } from '../../components/ui/DetailDialog'
import { fieldDescribedBy } from '../../components/ui/described-by'
import { FormField } from '../../components/ui/FormField'
import { controlClass, primaryButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { changedDriverFields } from '../../lib/driver-patch'
import { driverFieldErrors, type DriverField } from '../../lib/driver-errors'
import { canonicalPlate, parsePlate, plateLettersInput, plateNumbersInput } from '../../lib/egyptian-car-plate'
import { limitFavoriteIds } from '../../lib/favorites'
import { messageForApiError } from '../../lib/api-message'
import { FavoritePlacesField } from './FavoritePlacesField'

type DriverFormDialogProps = {
  mode: 'create' | 'edit' | null
  driver: Driver | null
  onClose: () => void
}

type FormValues = {
  name_en: string
  name_ar: string
  email: string
  phone: string
  national_id: string
  plate_letters: string
  plate_numbers: string
  personal_license: string
  password: string
}

const TEXT_FIELDS: Array<Exclude<DriverField, 'favorite_place_ids'>> = [
  'name_en',
  'name_ar',
  'email',
  'phone',
  'national_id',
  'car_license',
  'personal_license',
  'password',
]

export function DriverFormDialog({ mode, driver, onClose }: DriverFormDialogProps) {
  const { t } = useTranslation()
  const open = mode !== null
  return (
    <DetailDialog
      open={open}
      title={mode === 'edit' ? t('driverAdmin.edit') : t('driverAdmin.add')}
      onClose={onClose}
    >
      {mode ? (
        <DriverForm
          key={`${mode}-${driver?.id ?? 'new'}`}
          mode={mode}
          driver={driver}
          onClose={onClose}
        />
      ) : null}
    </DetailDialog>
  )
}

function DriverForm({
  mode,
  driver,
  onClose,
}: {
  mode: 'create' | 'edit'
  driver: Driver | null
  onClose: () => void
}) {
  const { t } = useTranslation()
  const toast = useToast()
  const places = useActivePlaces(true)
  const create = useCreateDriver()
  const update = useUpdateDriver()
  const [banner, setBanner] = useState<string | null>(null)
  const [favoriteError, setFavoriteError] = useState<string | null>(null)
  const [favoriteIds, setFavoriteIds] = useState<string[]>(driver?.favorite_place_ids ?? [])

  const parsedPlate = parsePlate(driver?.car_license ?? '')
  const schema = useMemo(() => driverSchema(mode, t), [mode, t])
  const {
    register,
    handleSubmit,
    setError,
    clearErrors,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name_en: driver?.name_en ?? '',
      name_ar: driver?.name_ar ?? '',
      email: driver?.email ?? '',
      phone: driver?.phone ?? '',
      national_id: driver?.national_id ?? '',
      plate_letters: parsedPlate?.letters ?? '',
      plate_numbers: parsedPlate?.numbers ?? '',
      personal_license: driver?.personal_license ?? '',
      password: '',
    },
  })

  async function onSubmit(values: FormValues) {
    clearErrors()
    setBanner(null)
    setFavoriteError(null)
    const favorites = limitFavoriteIds(favoriteIds)
    const plate = canonicalPlate(values.plate_letters, values.plate_numbers)
    if (!plate) return
    try {
      if (mode === 'create') {
        await create.mutateAsync({
          name_en: values.name_en.trim(),
          name_ar: values.name_ar.trim(),
          email: values.email.trim(),
          password: values.password,
          phone: values.phone.trim(),
          national_id: values.national_id.trim(),
          car_license: plate,
          personal_license: values.personal_license.trim(),
          favorite_place_ids: favorites,
        })
        toast(t('driverAdmin.created'), 'success')
      } else if (driver) {
        const body = changedDriverFields(driver, {
          name_en: values.name_en,
          name_ar: values.name_ar,
          phone: values.phone,
          national_id: values.national_id,
          car_license: plate,
          personal_license: values.personal_license,
          favorite_place_ids: favorites,
        })
        if (Object.keys(body).length === 0) {
          onClose()
          return
        }
        await update.mutateAsync({ id: driver.id, body })
        toast(t('driverAdmin.saved'), 'success')
      }
      onClose()
    } catch (error) {
      const mapped = driverFieldErrors(error)
      setFavoriteError(mapped.fields.favorite_place_ids ?? null)
      for (const field of TEXT_FIELDS) {
        const message = mapped.fields[field]
        if (!message) continue
        if (field === 'car_license') setError('plate_numbers', { message })
        else setError(field, { message })
      }
      if (mapped.banner) setBanner(mapped.banner)
      else if (Object.keys(mapped.fields).length === 0) setBanner(messageForApiError(error, t))
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
      <FormField id="driver-name-en" label={t('profile.nameEn')} error={errors.name_en?.message}>
        <input
          id="driver-name-en"
          className={controlClass}
          aria-describedby={fieldDescribedBy('driver-name-en', errors.name_en?.message)}
          {...register('name_en')}
        />
      </FormField>
      <FormField id="driver-name-ar" label={t('profile.nameAr')} error={errors.name_ar?.message}>
        <input
          id="driver-name-ar"
          className={controlClass}
          aria-describedby={fieldDescribedBy('driver-name-ar', errors.name_ar?.message)}
          {...register('name_ar')}
        />
      </FormField>
      <FormField
        id="driver-email"
        label={t('profile.email')}
        error={errors.email?.message}
        hint={mode === 'edit' ? t('driverAdmin.emailLocked') : undefined}
      >
        <input
          id="driver-email"
          type="email"
          className={controlClass}
          readOnly={mode === 'edit'}
          autoComplete="off"
          aria-describedby={fieldDescribedBy(
            'driver-email',
            errors.email?.message,
            mode === 'edit' ? t('driverAdmin.emailLocked') : undefined,
          )}
          {...register('email')}
        />
      </FormField>
      <FormField id="driver-phone" label={t('profile.phone')} error={errors.phone?.message}>
        <input
          id="driver-phone"
          type="text"
          className={controlClass}
          autoComplete="off"
          aria-describedby={fieldDescribedBy('driver-phone', errors.phone?.message)}
          {...register('phone')}
        />
      </FormField>
      <FormField
        id="driver-national-id"
        label={t('driverAdmin.nationalId')}
        error={errors.national_id?.message}
      >
        <input
          id="driver-national-id"
          type="text"
          className={controlClass}
          aria-describedby={fieldDescribedBy('driver-national-id', errors.national_id?.message)}
          {...register('national_id')}
        />
      </FormField>
      <fieldset className="flex flex-col gap-3">
        <legend className="text-sm font-semibold text-navy">{t('driverAdmin.carLicense')}</legend>
        <div className="grid gap-4 sm:grid-cols-2">
          <FormField
            id="driver-plate-letters"
            label={t('driverAdmin.plateLetters')}
            error={errors.plate_letters?.message}
          >
            <input
              id="driver-plate-letters"
              className={controlClass}
              dir="rtl"
              autoComplete="off"
              aria-describedby={fieldDescribedBy(
                'driver-plate-letters',
                errors.plate_letters?.message,
              )}
              {...plateField(register('plate_letters'), plateLettersInput)}
            />
          </FormField>
          <FormField
            id="driver-plate-numbers"
            label={t('driverAdmin.plateNumbers')}
            error={errors.plate_numbers?.message}
          >
            <input
              id="driver-plate-numbers"
              className={controlClass}
              inputMode="numeric"
              autoComplete="off"
              aria-describedby={fieldDescribedBy(
                'driver-plate-numbers',
                errors.plate_numbers?.message,
              )}
              {...plateField(register('plate_numbers'), plateNumbersInput)}
            />
          </FormField>
        </div>
      </fieldset>
      <FormField
        id="driver-personal-license"
        label={t('driverAdmin.personalLicense')}
        error={errors.personal_license?.message}
      >
        <input
          id="driver-personal-license"
          type="text"
          className={controlClass}
          aria-describedby={fieldDescribedBy(
            'driver-personal-license',
            errors.personal_license?.message,
          )}
          {...register('personal_license')}
        />
      </FormField>
      {places.isError ? (
        <p role="alert" className="text-sm text-danger">
          {messageForApiError(places.error, t)}
        </p>
      ) : (
        <FavoritePlacesField
          places={places.data ?? []}
          selectedIds={favoriteIds}
          onChange={setFavoriteIds}
          error={favoriteError ?? undefined}
          disabled={places.isPending}
        />
      )}
      {mode === 'create' ? (
        <FormField
          id="driver-password"
          label={t('driverAdmin.password')}
          error={errors.password?.message}
          hint={t('driverAdmin.passwordHint')}
        >
          <input
            id="driver-password"
            type="password"
            className={controlClass}
            autoComplete="new-password"
            aria-describedby={fieldDescribedBy(
              'driver-password',
              errors.password?.message,
              t('driverAdmin.passwordHint'),
            )}
            {...register('password')}
          />
        </FormField>
      ) : null}
      <button type="submit" className={primaryButtonClass} disabled={isSubmitting}>
        {isSubmitting ? t('common.loading') : t('common.save')}
      </button>
    </form>
  )
}

function plateField(
  field: ReturnType<ReturnType<typeof useForm<FormValues>>['register']>,
  format: (value: string) => string,
) {
  return {
    ...field,
    onChange: (event: ChangeEvent<HTMLInputElement>) => {
      event.target.value = format(event.target.value)
      void field.onChange(event)
    },
  }
}

function driverSchema(mode: 'create' | 'edit', t: (key: string) => string) {
  return z.object({
    name_en: z.string().trim().min(1, t('validation.required')).max(255),
    name_ar: z.string().trim().min(1, t('validation.required')).max(255),
    email:
      mode === 'create'
        ? z.string().trim().min(1, t('validation.required')).email(t('validation.email'))
        : z.string(),
    phone: z
      .string()
      .trim()
      .min(1, t('validation.required'))
      .regex(/^\+?[0-9\s-]{8,20}$/, t('validation.phone')),
    national_id: z.string().trim().min(1, t('validation.required')).max(100),
    plate_letters: z.string(),
    plate_numbers: z.string(),
    personal_license: z.string().trim().min(1, t('validation.required')).max(100),
    password: mode === 'create' ? z.string().min(8, t('validation.minPassword')) : z.string(),
  }).superRefine((values, context) => {
    if (canonicalPlate(values.plate_letters, values.plate_numbers) == null) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['plate_numbers'],
        message: t('validation.plate'),
      })
    }
  })
}
