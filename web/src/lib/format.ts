import type { TFunction } from 'i18next'

const CAIRO = 'Africa/Cairo'
const EMPTY = '—'

function parseDate(value: string | null | undefined): Date | null {
  if (!value) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

function isArabic(language: string): boolean {
  return language.startsWith('ar')
}

function cairoYear(date: Date): string {
  return new Intl.DateTimeFormat('en', { timeZone: CAIRO, year: 'numeric' }).format(date)
}

/** "Wed 26 Nov" in Cairo time; the year is added when it isn't this year. */
export function formatDate(value: string | null | undefined, language: string): string {
  const date = parseDate(value)
  if (!date) return EMPTY
  const otherYear = cairoYear(date) !== cairoYear(new Date())
  return new Intl.DateTimeFormat(isArabic(language) ? 'ar' : 'en-GB', {
    timeZone: CAIRO,
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    ...(otherYear ? { year: 'numeric' as const } : {}),
  })
    .format(date)
    .replace(',', '')
}

/** "Wed 26 Nov, 3:58 PM" in Cairo time; the time never wraps. */
export function formatDateTime(value: string | null | undefined, language: string): string {
  const date = parseDate(value)
  if (!date) return EMPTY
  const time = new Intl.DateTimeFormat(isArabic(language) ? 'ar' : 'en-US', {
    timeZone: CAIRO,
    hour: 'numeric',
    minute: '2-digit',
  })
    .format(date)
    .replace(/\s/g, ' ')
  return `${formatDate(value, language)}${isArabic(language) ? '،' : ','} ${time}`
}

/** Same as formatDateTime, but empty for missing values so callers choose the fallback. */
export function formatWhen(value: string | null | undefined, language: string): string {
  return parseDate(value) ? formatDateTime(value, language) : (value ?? '')
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
