import { ApiError } from '../api/errors'

const DRIVER_FIELDS = [
  'name_en',
  'name_ar',
  'email',
  'phone',
  'national_id',
  'car_license',
  'personal_license',
  'password',
] as const

export type DriverField = (typeof DRIVER_FIELDS)[number] | 'favorite_place_ids'

export function driverFieldErrors(error: unknown): {
  fields: Partial<Record<DriverField, string>>
  banner: string | null
} {
  if (!(error instanceof ApiError)) return { fields: {}, banner: null }
  const fields: Partial<Record<DriverField, string>> = {}
  let banner: string | null = error.message
  let sawField = false
  if (!error.errors) return { fields, banner }
  for (const [key, messages] of Object.entries(error.errors)) {
    const message = messages[0]
    if (!message) continue
    if (key === 'general') {
      banner = message
      continue
    }
    const field = fieldName(key)
    if (!field || fields[field]) continue
    fields[field] = message
    sawField = true
  }
  if (sawField && !error.errors.general?.[0]) banner = null
  return { fields, banner }
}

function fieldName(key: string): DriverField | null {
  if (key === 'favorite_place_ids' || key.startsWith('favorite_place_ids.')) {
    return 'favorite_place_ids'
  }
  if ((DRIVER_FIELDS as readonly string[]).includes(key)) return key as DriverField
  return null
}
