import type { WebRole } from '../api/types'
import type { AppNotification } from '../api/notifications'

export function notificationValues(
  params: Record<string, string>,
  language: string,
): Record<string, string> {
  const arabic = language.startsWith('ar')
  const name = (prefix: string) => {
    const localized = params[`${prefix}_ar`] ?? ''
    const english = params[`${prefix}_en`] ?? ''
    if (arabic && localized !== '') return localized
    return english
  }
  return {
    requester: name('requester_name'),
    driver: name('driver_name'),
    pickup: params.pickup ?? '',
    destination: params.destination ?? '',
  }
}

function myTripsPath(role: WebRole): string {
  if (role === 'admin') return '/admin/my-trips'
  if (role === 'company_admin') return '/company-admin/my-trips'
  return '/drivers-admin/my-trips'
}

/** Screen opened when a notification is tapped. */
export function notificationHref(role: WebRole, item: AppNotification): string | null {
  const requestId = item.trip_request_id
  const tripId = item.trip_id
  switch (item.type) {
    case 'trip_ended_report_needed':
      if (!tripId) return null
      return `${myTripsPath(role)}?trip=${encodeURIComponent(tripId)}&report=1`
    case 'request_submitted':
      if (!requestId) return null
      return `/company-admin?request=${encodeURIComponent(requestId)}`
    case 'trip_ready_to_assign':
      if (!requestId) return null
      return `/drivers-admin?request=${encodeURIComponent(requestId)}`
    case 'trip_assigned':
    case 'own_trip_assigned':
      if (!tripId) return null
      return `${myTripsPath(role)}?trip=${encodeURIComponent(tripId)}`
    default:
      return null
  }
}
