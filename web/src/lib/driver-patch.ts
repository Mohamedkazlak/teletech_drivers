import type { UpdateDriverBody } from '../api/drivers'
import type { Driver } from '../api/types'

export type DriverDraft = {
  name_en: string
  name_ar: string
  phone: string
  national_id: string
  car_license: string
  personal_license: string
  favorite_place_ids: string[]
}

export function changedDriverFields(original: Driver, next: DriverDraft): UpdateDriverBody {
  const body: UpdateDriverBody = {}
  const nameEn = next.name_en.trim()
  const nameAr = next.name_ar.trim()
  if (nameEn !== original.name_en) body.name_en = nameEn
  if (nameAr !== (original.name_ar ?? '')) body.name_ar = nameAr
  const phone = next.phone.trim()
  if (phone !== (original.phone ?? '')) body.phone = phone
  if (next.national_id.trim() !== original.national_id) body.national_id = next.national_id.trim()
  if (next.car_license.trim() !== original.car_license) body.car_license = next.car_license.trim()
  if (next.personal_license.trim() !== original.personal_license) {
    body.personal_license = next.personal_license.trim()
  }
  if (!sameIds(next.favorite_place_ids, original.favorite_place_ids)) {
    body.favorite_place_ids = next.favorite_place_ids
  }
  return body
}

function sameIds(left: string[], right: string[]): boolean {
  if (left.length !== right.length) return false
  return left.every((id, index) => id === right[index])
}
