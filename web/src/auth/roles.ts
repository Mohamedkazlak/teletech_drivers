import type { UserRole, WebRole } from '../api/types'

const WEB_ROLES: readonly WebRole[] = ['admin', 'company_admin', 'drivers_admin']

export function isWebRole(role: UserRole): role is WebRole {
  return WEB_ROLES.includes(role as WebRole)
}

export function homePath(role: WebRole): string {
  if (role === 'admin') return '/admin'
  if (role === 'company_admin') return '/company-admin'
  return '/drivers-admin'
}
