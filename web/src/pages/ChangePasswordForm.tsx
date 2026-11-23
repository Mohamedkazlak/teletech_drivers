import { zodResolver } from '@hookform/resolvers/zod'
import { useMemo, useState } from 'react'
import { useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import { z } from 'zod'
import { api } from '../api/client'
import type { User } from '../api/types'
import { useAuth } from '../auth/auth-context'
import { fieldDescribedBy } from '../components/ui/described-by'
import { FormField } from '../components/ui/FormField'
import { useToast } from '../components/ui/toast-context'
import { controlClass, primaryButtonClass } from '../components/ui/styles'
import { applyFieldErrors } from '../lib/form-errors'

type ChangePasswordFormProps = {
  onSuccess?: (user: User) => void
}

export function ChangePasswordForm({ onSuccess }: ChangePasswordFormProps) {
  const { t } = useTranslation()
  const { refresh } = useAuth()
  const toast = useToast()
  const [banner, setBanner] = useState<string | null>(null)

  const schema = useMemo(
    () =>
      z
        .object({
          current_password: z.string().min(1, t('validation.required')),
          password: z.string().min(8, t('validation.minPassword')),
          password_confirmation: z.string().min(1, t('validation.required')),
        })
        .refine((value) => value.password === value.password_confirmation, {
          path: ['password_confirmation'],
          message: t('validation.passwordMatch'),
        }),
    [t],
  )

  type Values = z.infer<typeof schema>

  const {
    register,
    handleSubmit,
    setError,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: { current_password: '', password: '', password_confirmation: '' },
  })

  async function onSubmit(values: Values) {
    setBanner(null)
    try {
      await api.post('/auth/change-password', values)
      const next = await refresh()
      reset()
      toast(t('auth.passwordChanged'), 'success')
      if (next) onSuccess?.(next)
    } catch (error) {
      setBanner(
        applyFieldErrors(error, setError, [
          'current_password',
          'password',
          'password_confirmation',
        ]),
      )
    }
  }

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={(event) => void handleSubmit(onSubmit)(event)}
      noValidate
    >
      {banner ? (
        <p role="alert" className="rounded-control bg-danger/10 px-3 py-2 text-sm text-danger">
          {banner}
        </p>
      ) : null}
      <FormField
        id="current_password"
        label={t('auth.currentPassword')}
        error={errors.current_password?.message}
      >
        <input
          id="current_password"
          type="password"
          autoComplete="current-password"
          className={controlClass}
          aria-invalid={Boolean(errors.current_password)}
          aria-describedby={fieldDescribedBy('current_password', errors.current_password?.message)}
          {...register('current_password')}
        />
      </FormField>
      <FormField
        id="password"
        label={t('auth.newPassword')}
        hint={t('auth.passwordHint')}
        error={errors.password?.message}
      >
        <input
          id="password"
          type="password"
          autoComplete="new-password"
          className={controlClass}
          aria-invalid={Boolean(errors.password)}
          aria-describedby={fieldDescribedBy(
            'password',
            errors.password?.message,
            t('auth.passwordHint'),
          )}
          {...register('password')}
        />
      </FormField>
      <FormField
        id="password_confirmation"
        label={t('auth.confirmPassword')}
        error={errors.password_confirmation?.message}
      >
        <input
          id="password_confirmation"
          type="password"
          autoComplete="new-password"
          className={controlClass}
          aria-invalid={Boolean(errors.password_confirmation)}
          aria-describedby={fieldDescribedBy(
            'password_confirmation',
            errors.password_confirmation?.message,
          )}
          {...register('password_confirmation')}
        />
      </FormField>
      <button type="submit" className={primaryButtonClass} disabled={isSubmitting}>
        {t('auth.changePassword')}
      </button>
    </form>
  )
}
