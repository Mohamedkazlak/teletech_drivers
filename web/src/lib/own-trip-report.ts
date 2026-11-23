import type { TripSummary, User } from '../api/types'

const reportRoles = new Set<User['role']>(['employee', 'company_admin', 'drivers_admin'])

/** Request the signed-in requester may confirm. Everyone else gets null. */
export function ownPendingRequestId(trip: TripSummary, user: User | null): string | null {
  if (user == null || !reportRoles.has(user.role)) return null
  if (trip.status !== 'completed' || trip.confirmation_status !== 'pending') return null
  const passenger = trip.passengers.find((item) => item.employee_id === user.id)
  if (passenger == null || passenger.request_id === '') return null
  return passenger.request_id
}
