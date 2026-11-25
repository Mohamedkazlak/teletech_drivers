import type { WebRole } from '../../api/types'

export type NavIcon =
  | 'dashboard'
  | 'drivers'
  | 'employees'
  | 'users'
  | 'places'
  | 'trips'
  | 'requests'
  | 'myTrips'
  | 'attendance'
  | 'liveMap'
  | 'reports'

export type NavItem = {
  to: string
  labelKey: string
  end?: boolean
  icon?: NavIcon
}

export const NAV: Record<WebRole, NavItem[]> = {
  admin: [
    { to: '/admin', labelKey: 'nav.dashboard', end: true, icon: 'dashboard' },
    { to: '/admin/drivers', labelKey: 'nav.drivers', icon: 'drivers' },
    { to: '/admin/employees', labelKey: 'nav.employees', icon: 'employees' },
    { to: '/admin/users', labelKey: 'nav.users', icon: 'users' },
    { to: '/admin/places', labelKey: 'nav.places', icon: 'places' },
    { to: '/admin/trips', labelKey: 'nav.trips', icon: 'trips' },
    { to: '/admin/trip-requests', labelKey: 'nav.tripRequests', icon: 'requests' },
    { to: '/admin/my-trips', labelKey: 'nav.myTrips', icon: 'myTrips' },
    { to: '/admin/attendance', labelKey: 'nav.attendance', icon: 'attendance' },
    { to: '/admin/live-map', labelKey: 'nav.liveMap', icon: 'liveMap' },
  ],
  company_admin: [
    { to: '/company-admin', labelKey: 'nav.requestedTrips', end: true, icon: 'requests' },
    { to: '/company-admin/my-trips', labelKey: 'nav.myTrips', icon: 'myTrips' },
    { to: '/company-admin/trips', labelKey: 'nav.trips', icon: 'trips' },
    { to: '/company-admin/places', labelKey: 'nav.places', icon: 'places' },
    { to: '/company-admin/driver-reports', labelKey: 'nav.driverReports', icon: 'reports' },
  ],
  drivers_admin: [
    { to: '/drivers-admin', labelKey: 'nav.requests', end: true, icon: 'requests' },
    { to: '/drivers-admin/trips', labelKey: 'nav.trips', icon: 'trips' },
    { to: '/drivers-admin/my-trips', labelKey: 'nav.myTrips', icon: 'myTrips' },
    { to: '/drivers-admin/drivers', labelKey: 'nav.drivers', icon: 'drivers' },
    { to: '/drivers-admin/attendance', labelKey: 'nav.attendance', icon: 'attendance' },
    { to: '/drivers-admin/live-map', labelKey: 'nav.liveMap', icon: 'liveMap' },
  ],
}
