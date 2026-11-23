import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import ar from './locales/ar'
import en from './locales/en'

export const LOCALE_KEY = 'teletech.locale'

function storedLocale(): 'en' | 'ar' {
  const stored = localStorage.getItem(LOCALE_KEY)
  return stored === 'ar' ? 'ar' : 'en'
}

export function applyDocumentLocale(language: string): void {
  const code = language.startsWith('ar') ? 'ar' : 'en'
  document.documentElement.lang = code
  document.documentElement.dir = code === 'ar' ? 'rtl' : 'ltr'
  document.title = i18n.t('app.name')
  localStorage.setItem(LOCALE_KEY, code)
}

void i18n.use(initReactI18next).init({
  resources: {
    en: { translation: en },
    ar: { translation: ar },
  },
  lng: storedLocale(),
  fallbackLng: 'en',
  interpolation: { escapeValue: false },
})

i18n.on('languageChanged', applyDocumentLocale)
applyDocumentLocale(i18n.language)

export default i18n
