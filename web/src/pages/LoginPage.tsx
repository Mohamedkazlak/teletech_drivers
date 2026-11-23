import { zodResolver } from '@hookform/resolvers/zod'
import { useMemo, useState } from 'react'
import { useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'
import { z } from 'zod'
import { useAuth } from '../auth/auth-context'
import { homePath, isWebRole } from '../auth/roles'
import { fieldDescribedBy } from '../components/ui/described-by'
import { FormField } from '../components/ui/FormField'
import { AuthFrame } from '../components/layout/AuthFrame'
import { alertClass, controlClass, primaryButtonClass } from '../components/ui/styles'

export function LoginPage() {
  const { t } = useTranslation()
  const { login } = useAuth()
  const navigate = useNavigate()
  const [banner, setBanner] = useState<string | null>(null)

  const schema = useMemo(
    () =>
      z.object({
        email: z.string().min(1, t('validation.required')).email(t('validation.email')),
        password: z.string().min(1, t('validation.required')),
      }),
    [t],
  )
  type Values = z.infer<typeof schema>

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: { email: '', password: '' },
  })

  async function onSubmit(values: Values) {
    setBanner(null)
    const result = await login(values.email, values.password)
    if (!result.ok) {
      setBanner(
        result.reason === 'mobile-only'
          ? t('auth.mobileOnly')
          : result.status === 0
            ? t('common.network')
            : result.message,
      )
      return
    }
    if (!isWebRole(result.user.role)) return
    navigate(result.user.must_change_password ? '/change-password' : homePath(result.user.role), {
      replace: true,
    })
  }

  return (
    <AuthFrame title={t('app.name')} subtitle={t('app.tagline')}>
      <form
        className="flex flex-col gap-4"
        onSubmit={(event) => void handleSubmit(onSubmit)(event)}
        noValidate
      >
        {banner ? (
          <p role="alert" className={alertClass}>
            {banner}
          </p>
        ) : null}
        <FormField id="email" label={t('auth.email')} error={errors.email?.message}>
          <input
            id="email"
            type="email"
            autoComplete="username"
            className={controlClass}
            aria-invalid={Boolean(errors.email)}
            aria-describedby={fieldDescribedBy('email', errors.email?.message)}
            {...register('email')}
          />
        </FormField>
        <FormField id="password" label={t('auth.password')} error={errors.password?.message}>
          <input
            id="password"
            type="password"
            autoComplete="current-password"
            className={controlClass}
            aria-invalid={Boolean(errors.password)}
            aria-describedby={fieldDescribedBy('password', errors.password?.message)}
            {...register('password')}
          />
        </FormField>
        <button type="submit" className={primaryButtonClass} disabled={isSubmitting}>
          {isSubmitting ? t('auth.signingIn') : t('auth.signIn')}
        </button>
      </form>
    </AuthFrame>
  )
}
