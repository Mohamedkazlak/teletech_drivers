import { useTranslation } from 'react-i18next'
import { PageHeading } from '../components/layout/AppShell'
import { LanguageToggle } from '../components/language/LanguageToggle'
import { ChangePasswordForm } from './ChangePasswordForm'

export function SettingsPage() {
  const { t } = useTranslation()
  return (
    <section className="mx-auto flex max-w-2xl flex-col gap-5">
      <PageHeading title={t('settings.title')} />
      <section className="rounded-card border border-pale bg-white p-5">
        <h2 className="mb-3 text-base font-bold text-navy">{t('settings.language')}</h2>
        <LanguageToggle />
      </section>
      <section className="rounded-card border border-pale bg-white p-5">
        <h2 className="mb-4 text-base font-bold text-navy">{t('settings.password')}</h2>
        <ChangePasswordForm />
      </section>
    </section>
  )
}
