import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Account } from '../../api/users'
import { useResetUserPassword } from '../../api/use-users'
import { fieldDescribedBy } from '../../components/ui/described-by'
import { FormField } from '../../components/ui/FormField'
import { ConfirmDialog } from '../../components/ui/ConfirmDialog'
import { controlClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { messageForApiError } from '../../lib/api-message'
import { localizedName } from '../../lib/names'

type ResetPasswordDialogProps = {
  account: Account | null
  onClose: () => void
}

export function ResetPasswordDialog({ account, onClose }: ResetPasswordDialogProps) {
  return (
    <ResetPasswordForm key={account?.id ?? 'closed'} account={account} onClose={onClose} />
  )
}

function ResetPasswordForm({ account, onClose }: ResetPasswordDialogProps) {
  const { t, i18n } = useTranslation()
  const toast = useToast()
  const reset = useResetUserPassword()
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [error, setError] = useState<string | null>(null)
  const name = account ? localizedName(i18n.language, account.name_en, account.name_ar) : ''

  async function submit() {
    if (!account) return
    if (password.length < 8) {
      setError(t('validation.minPassword'))
      return
    }
    if (password !== confirmation) {
      setError(t('validation.passwordMatch'))
      return
    }
    setError(null)
    try {
      await reset.mutateAsync({ id: account.id, password })
      toast(t('users.saved'), 'success')
      onClose()
    } catch (caught) {
      setError(messageForApiError(caught, t))
    }
  }

  return (
    <ConfirmDialog
      open={account !== null}
      title={t('users.resetTitle')}
      description={account ? t('users.resetMessage', { name }) : ''}
      confirmLabel={t('users.reset')}
      cancelLabel={t('common.cancel')}
      busy={reset.isPending}
      confirmDisabled={password.length === 0 || confirmation.length === 0}
      onCancel={onClose}
      onConfirm={() => {
        void submit()
      }}
    >
      <div className="flex flex-col gap-3">
        <p className="text-sm text-navy/75">{t('users.passwordHint')}</p>
        {error ? (
          <p role="alert" className="text-sm text-danger">
            {error}
          </p>
        ) : null}
        <FormField
          id="reset-password"
          label={t('users.password')}
          hint={t('auth.passwordHint')}
        >
          <input
            id="reset-password"
            className={controlClass}
            type="password"
            autoComplete="new-password"
            value={password}
            aria-describedby={fieldDescribedBy('reset-password', undefined, t('auth.passwordHint'))}
            onChange={(event) => setPassword(event.target.value)}
          />
        </FormField>
        <FormField id="reset-password-confirm" label={t('users.confirm')}>
          <input
            id="reset-password-confirm"
            className={controlClass}
            type="password"
            autoComplete="new-password"
            value={confirmation}
            onChange={(event) => setConfirmation(event.target.value)}
          />
        </FormField>
      </div>
    </ConfirmDialog>
  )
}
