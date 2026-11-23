import type { Place } from '../../api/types'
import type { UpdatePlaceBody } from '../../api/places'

export type PlaceDraft = {
  name_en: string
  name_ar: string
  address: string
  latitude: number | null
  longitude: number | null
  is_headquarters: boolean
  is_active: boolean
}

export function changedPlaceFields(original: Place, next: PlaceDraft): UpdatePlaceBody {
  const body: UpdatePlaceBody = {}
  if (next.name_en !== original.name_en) body.name_en = next.name_en
  if (next.name_ar !== original.name_ar) body.name_ar = next.name_ar
  const address = next.address.trim() === '' ? null : next.address.trim()
  if (address !== original.address) body.address = address
  if (
    !sameNumber(next.latitude, original.latitude) ||
    !sameNumber(next.longitude, original.longitude)
  ) {
    body.latitude = next.latitude
    body.longitude = next.longitude
  }
  if (next.is_headquarters !== original.is_headquarters) body.is_headquarters = next.is_headquarters
  if (next.is_active !== original.is_active) body.is_active = next.is_active
  return body
}

function sameNumber(left: number | null, right: number | null): boolean {
  if (left === null || right === null) return left === right
  return left === right
}
