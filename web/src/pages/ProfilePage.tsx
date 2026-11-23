import { zodResolver } from '@hookform/resolvers/zod'
import { useMemo, useState } from 'react'
import { useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import { z } from 'zod'
import { api } from '../api/client'
import type { Branch, UpdateProfileBody } from '../api/types'
import { useAuth } from '../auth/auth-context'
import { PageHeading } from '../components/layout/AppShell'
import { FormField } from '../components/ui/FormField'
import { StatusBadge } from '../components/ui/StatusBadge'
import { controlClass, primaryButtonClass } from '../components/ui/styles'
import { useToast } from '../components/ui/toast-context'
import { applyFieldErrors } from '../lib/form-errors'

export function ProfilePage() {
  const { t } = useTranslation()
  const { user, refresh } = useAuth()
  const toast = useToast()
  const [banner, setBanner] = useState<string | null>(null)

  const schema = useMemo(
    () =>
      z.object({
        name_en: z.string().min(1, t('validation.required')).max(255),
        name_ar: z.string().max(255),
        phone: z.string().max(50),
        email: z.string().min(1, t('validation.required')).email(t('validation.email')),
        branch: z.enum(['', 'company_headquarters', 'new_headquarters']),
      }),
    [t],
  )
  type Values = z.infer<typeof schema>

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<Values>({
    resolver: zodResolver(schema),
    values: {
      name_en: user?.name_en ?? '',
      name_ar: user?.name_ar ?? '',
      phone: user?.phone ?? '',
      email: user?.email ?? '',
      branch: user?.branch ?? '',
    },
  })

  async function onSubmit(values: Values) {
    setBanner(null)
    const body: UpdateProfileBody = {
      name_en: values.name_en,
      name_ar: values.name_ar.trim() === '' ? null : values.name_ar,
      phone: values.phone.trim() === '' ? null : values.phone,
      email: values.email,
    }
    if (user?.role === 'admin') {
      body.branch = values.branch === '' ? null : (values.branch as Branch)
    }
    try {
      await api.patch('/auth/me', body)
      await refresh()
      toast(t('profile.saved'), 'success')
    } catch (error) {
      setBanner(
        applyFieldErrors(error, setError, ['name_en', 'name_ar', 'phone', 'email', 'branch']),
      )
    }
  }

  if (!user) return null

  return (
    <section className="mx-auto max-w-2xl">
      <PageHeading title={t('profile.title')} />
      <div className="mb-4 flex flex-wrap items-center gap-2 text-sm text-navy/75">
        <span>{t('profile.role')}</span>
        <span className="font-medium text-navy">{t(`role.${user.role}`)}</span>
        {user.role === 'driver' ? (
          <StatusBadge status={user.is_available ? 'checked_in' : 'not_checked_in'} />
        ) : null}
      </div>
      <form
        className="flex flex-col gap-4 rounded-card border border-pale bg-white p-5"
        onSubmit={(event) => void handleSubmit(onSubmit)(event)}
        noValidate
      >
        {banner ? (
          <p role="alert" className="rounded-control bg-danger/10 px-3 py-2 text-sm text-danger">
            {banner}
          </p>
        ) : null}
        <FormField id="name_en" label={t('profile.nameEn')} error={errors.name_en?.message}>
          <input id="name_en" className={controlClass} {...register('name_en')} />
        </FormField>
        <FormField id="name_ar" label={t('profile.nameAr')} error={errors.name_ar?.message}>
          <input id="name_ar" className={controlClass} {...register('name_ar')} />
        </FormField>
        <FormField id="phone" label={t('profile.phone')} error={errors.phone?.message}>
          <input id="phone" className={controlClass} {...register('phone')} />
        </FormField>
        <FormField id="email" label={t('profile.email')} error={errors.email?.message}>
          <input
            id="email"
            type="email"
            autoComplete="email"
            className={controlClass}
            {...register('email')}
          />
        </FormField>
        <FormField id="branch" label={t('profile.branch')} error={errors.branch?.message}>
          {user.role === 'admin' ? (
            <select id="branch" className={controlClass} {...register('branch')}>
              <option value="">{t('profile.none')}</option>
              <option value="company_headquarters">{t('branch.company_headquarters')}</option>
              <option value="new_headquarters">{t('branch.new_headquarters')}</option>
            </select>
          ) : (
            <div className="flex flex-col gap-1">
              <p id="branch" className="text-sm font-medium text-navy">
                {user.branch ? t(`branch.${user.branch}`) : t('profile.none')}
              </p>
              <p className="text-sm text-navy/75">{t('profile.branchLocked')}</p>
            </div>
          )}
        </FormField>
        <div>
          <button type="submit" className={primaryButtonClass} disabled={isSubmitting}>
            {t('common.save')}
          </button>
        </div>
      </form>
    </section>
  )
}
