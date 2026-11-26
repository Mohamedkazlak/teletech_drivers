import { useTranslation } from 'react-i18next'

type LanguageToggleProps = {
  /** "dark" sits on the navy auth header; "light" in the top bar. */
  tone?: 'light' | 'dark'
  /** Short "EN" / "ع" labels for narrow screens; full names stay as accessible names. */
  compact?: boolean
}

/** Segmented English / العربية switch with a sliding thumb. */
export function LanguageToggle({ tone = 'light', compact = false }: LanguageToggleProps) {
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
        aria-label={compact ? 'English' : undefined}
        className={buttonClass(current === 'en', dark, compact)}
        onClick={() => {
          void i18n.changeLanguage('en')
        }}
      >
        {compact ? 'EN' : 'English'}
      </button>
      <button
        type="button"
        aria-pressed={current === 'ar'}
        aria-label={compact ? 'العربية' : undefined}
        className={buttonClass(current === 'ar', dark, compact)}
        onClick={() => {
          void i18n.changeLanguage('ar')
        }}
      >
        {compact ? 'ع' : 'العربية'}
      </button>
    </div>
  )
}

function buttonClass(selected: boolean, dark: boolean, compact: boolean): string {
  const width = compact ? 'min-w-10' : 'min-w-[4.75rem]'
  const base = `relative z-10 h-10 ${width} rounded-full px-3 text-[13px] font-semibold transition-colors duration-200`
  if (selected) return `${base} text-navy`
  return `${base} ${dark ? 'text-white/80 hover:text-white' : 'text-ink-muted hover:text-navy'}`
}
