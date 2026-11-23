import type { UpdateEmployeeBody } from '../../api/employees'
import type { Branch, Employee } from '../../api/types'

export type EmployeeDraft = {
  name_en: string
  name_ar: string
  email: string
  phone: string
  branch: Branch | ''
}

export function changedEmployeeFields(original: Employee, next: EmployeeDraft): UpdateEmployeeBody {
  const body: UpdateEmployeeBody = {}
  const nameEn = next.name_en.trim()
  if (nameEn !== original.name_en) body.name_en = nameEn
  const nameAr = blankToNull(next.name_ar)
  if (nameAr !== original.name_ar) body.name_ar = nameAr
  const email = next.email.trim()
  if (email !== original.email) body.email = email
  const phone = blankToNull(next.phone)
  if (phone !== original.phone) body.phone = phone
  const branch = next.branch === '' ? null : next.branch
  if (branch !== original.branch) body.branch = branch
  return body
}

function blankToNull(value: string): string | null {
  const trimmed = value.trim()
  return trimmed === '' ? null : trimmed
}
