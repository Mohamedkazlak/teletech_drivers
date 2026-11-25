import { useTranslation } from 'react-i18next'

type LanguageToggleProps = {
  /** "dark" sits on the navy auth header; "light" in the top bar. */
  tone?: 'light' | 'dark'
}

/** Segmented English / العربية switch with a sliding thumb. */
export function LanguageToggle({ tone = 'light' }: LanguageToggleProps) {
  const { i18n, t } = useTranslation()
  const current = i18n.language.startsWith('ar') ? 'ar' : 'en'
  const dark = tone === 'dark'
  // Thumb position is logical (start/end), so it follows the text direction.
  const onEnd = current === 'ar'

  return (
    <div
      role="group"
      aria-label={t('settings.language')}
      className={`relative inline-grid grid-cols-2 rounded-full p-[3px] ${
        dark ? 'bg-white/12 ring-1 ring-white/20 backdrop-blur-sm' : 'bg-scaffold ring-1 ring-line'
      }`}
    >
      <span
        aria-hidden="true"
        className={`absolute inset-y-[3px] start-[3px] w-[calc(50%-3px)] rounded-full shadow-[0_1px_3px_rgb(7_21_51/0.18)] transition-transform duration-[260ms] ease-[var(--ease-in-out)] ${
          dark ? 'bg-white' : 'bg-white'
        } ${onEnd ? 'translate-x-full rtl:-translate-x-full' : ''}`}
      />
      <button
        type="button"
        aria-pressed={current === 'en'}
        className={buttonClass(current === 'en', dark)}
        onClick={() => {
          void i18n.changeLanguage('en')
        }}
      >
        English
      </button>
      <button
        type="button"
        aria-pressed={current === 'ar'}
        className={buttonClass(current === 'ar', dark)}
        onClick={() => {
          void i18n.changeLanguage('ar')
        }}
      >
        العربية
      </button>
    </div>
  )
}

function buttonClass(selected: boolean, dark: boolean): string {
  const base =
    'relative z-10 h-8 min-w-[4.75rem] rounded-full px-3 text-[13px] font-semibold transition-colors duration-200'
  if (selected) return `${base} text-navy`
  return `${base} ${dark ? 'text-white/80 hover:text-white' : 'text-ink-muted hover:text-navy'}`
}
