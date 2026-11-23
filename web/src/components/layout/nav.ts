import type { WebRole } from '../../api/types'

export type NavItem = {
  to: string
  labelKey: string
  end?: boolean
}

export const NAV: Record<WebRole, NavItem[]> = {
  admin: [
    { to: '/admin', labelKey: 'nav.dashboard', end: true },
    { to: '/admin/drivers', labelKey: 'nav.drivers' },
    { to: '/admin/employees', labelKey: 'nav.employees' },
    { to: '/admin/users', labelKey: 'nav.users' },
    { to: '/admin/places', labelKey: 'nav.places' },
    { to: '/admin/trips', labelKey: 'nav.trips' },
    { to: '/admin/trip-requests', labelKey: 'nav.tripRequests' },
    { to: '/admin/my-trips', labelKey: 'nav.myTrips' },
    { to: '/admin/attendance', labelKey: 'nav.attendance' },
    { to: '/admin/live-map', labelKey: 'nav.liveMap' },
  ],
  company_admin: [
    { to: '/company-admin', labelKey: 'nav.requestedTrips', end: true },
    { to: '/company-admin/my-trips', labelKey: 'nav.myTrips' },
    { to: '/company-admin/trips', labelKey: 'nav.trips' },
    { to: '/company-admin/places', labelKey: 'nav.places' },
    { to: '/company-admin/driver-reports', labelKey: 'nav.driverReports' },
  ],
  drivers_admin: [
    { to: '/drivers-admin', labelKey: 'nav.requests', end: true },
    { to: '/drivers-admin/trips', labelKey: 'nav.trips' },
    { to: '/drivers-admin/my-trips', labelKey: 'nav.myTrips' },
    { to: '/drivers-admin/drivers', labelKey: 'nav.drivers' },
    { to: '/drivers-admin/attendance', labelKey: 'nav.attendance' },
    { to: '/drivers-admin/live-map', labelKey: 'nav.liveMap' },
  ],
}
