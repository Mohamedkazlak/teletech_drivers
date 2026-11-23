const cairoZone = 'Africa/Cairo'

type CairoParts = {
  year: number
  month: number
  day: number
  hour: number
  minute: number
  second: number
}

export function cairoParts(instant: Date): CairoParts {
  const formatter = new Intl.DateTimeFormat('en-GB', {
    timeZone: cairoZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  })
  const map: Record<string, string> = {}
  for (const part of formatter.formatToParts(instant)) {
    if (part.type !== 'literal') map[part.type] = part.value
  }
  return {
    year: Number(map.year),
    month: Number(map.month),
    day: Number(map.day),
    hour: Number(map.hour),
    minute: Number(map.minute),
    second: Number(map.second),
  }
}

function pad(value: number): string {
  return String(value).padStart(2, '0')
}

/** `YYYY-MM-DDTHH:mm` for a Cairo wall clock. */
export function formatCairoInput(parts: {
  year: number
  month: number
  day: number
  hour: number
  minute: number
}): string {
  return `${parts.year}-${pad(parts.month)}-${pad(parts.day)}T${pad(parts.hour)}:${pad(parts.minute)}`
}

/** First minute strictly after [now] in Africa/Cairo. */
export function nextSlotInput(now = new Date()): string {
  const parts = cairoParts(now)
  const slot = new Date(Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute))
  slot.setUTCMinutes(slot.getUTCMinutes() + 1)
  return formatCairoInput({
    year: slot.getUTCFullYear(),
    month: slot.getUTCMonth() + 1,
    day: slot.getUTCDate(),
    hour: slot.getUTCHours(),
    minute: slot.getUTCMinutes(),
  })
}

const inputPattern = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/

/** Interprets a datetime-local value as Africa/Cairo (UTC+2) and returns ISO-8601. */
export function cairoInputToIso(value: string): string {
  const match = inputPattern.exec(value)
  if (!match) return new Date(value).toISOString()
  const utc = Date.UTC(
    Number(match[1]),
    Number(match[2]) - 1,
    Number(match[3]),
    Number(match[4]) - 2,
    Number(match[5]),
  )
  return new Date(utc).toISOString()
}

export function isoToCairoInput(value: string): string {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  const parts = cairoParts(date)
  return formatCairoInput(parts)
}

/** True when the Cairo minute is strictly after [now]. */
export function isFutureCairoInput(value: string, now = new Date()): boolean {
  if (!inputPattern.test(value)) return false
  const time = new Date(cairoInputToIso(value)).getTime()
  return !Number.isNaN(time) && time > now.getTime()
}
