import { useTranslation } from 'react-i18next'

export function LanguageToggle() {
  const { i18n, t } = useTranslation()
  const current = i18n.language.startsWith('ar') ? 'ar' : 'en'

  return (
    <div
      role="group"
      aria-label={t('settings.language')}
      className="inline-flex overflow-hidden rounded-control border-[1.5px] border-mid bg-pale"
    >
      <button
        type="button"
        aria-pressed={current === 'en'}
        className={buttonClass(current === 'en')}
        onClick={() => {
          void i18n.changeLanguage('en')
        }}
      >
        English
      </button>
      <button
        type="button"
        aria-pressed={current === 'ar'}
        className={buttonClass(current === 'ar')}
        onClick={() => {
          void i18n.changeLanguage('ar')
        }}
      >
        العربية
      </button>
    </div>
  )
}

function buttonClass(selected: boolean): string {
  return selected
    ? 'h-9 bg-white px-3 text-sm font-bold text-deep'
    : 'h-9 px-3 text-sm font-medium text-navy/55 hover:bg-white'
}
