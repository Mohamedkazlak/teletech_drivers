import type { TFunction } from 'i18next'

export function formatWhen(value: string | null | undefined, language: string): string {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat(language.startsWith('ar') ? 'ar' : 'en', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date)
}

export function formatDuration(seconds: number, t: TFunction): string {
  const total = Math.max(0, Math.round(seconds))
  const hours = Math.floor(total / 3600)
  const minutes = Math.floor((total % 3600) / 60)
  if (hours === 0) return t('format.minutes', { count: minutes })
  return t('format.hoursMinutes', { hours, minutes })
}

export function toIsoFromLocalInput(value: string): string {
  return new Date(value).toISOString()
}

export function toLocalDateTimeInput(value: string): string {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  const pad = (part: number) => String(part).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}

/** Trip report distances are already kilometres. */
export function formatDistanceKm(km: number, language: string): string {
  return new Intl.NumberFormat(language.startsWith('ar') ? 'ar' : 'en', {
    maximumFractionDigits: 1,
  }).format(km)
}

export function formatLengthFromMeters(meters: number, language: string, t: TFunction): string {
  const locale = language.startsWith('ar') ? 'ar' : 'en'
  if (Math.abs(meters) >= 1000) {
    const value = new Intl.NumberFormat(locale, { maximumFractionDigits: 1 }).format(meters / 1000)
    return t('format.kilometers', { value })
  }
  const value = new Intl.NumberFormat(locale, { maximumFractionDigits: 0 }).format(meters)
  return t('format.meters', { value })
}
