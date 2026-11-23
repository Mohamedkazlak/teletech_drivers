import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'
import type { User } from '../api/types'
import { useAuth } from '../auth/auth-context'
import { homePath, isWebRole } from '../auth/roles'
import { AuthFrame } from '../components/layout/AuthFrame'
import { ChangePasswordForm } from './ChangePasswordForm'

export function ChangePasswordPage() {
  const { t } = useTranslation()
  const { user } = useAuth()
  const navigate = useNavigate()

  return (
    <AuthFrame
      title={t('auth.changePassword')}
      subtitle={user?.must_change_password ? t('auth.mustChange') : null}
    >
      <ChangePasswordForm
        onSuccess={(next: User) => {
          if (isWebRole(next.role) && !next.must_change_password) {
            navigate(homePath(next.role), { replace: true })
          }
        }}
      />
    </AuthFrame>
  )
}
