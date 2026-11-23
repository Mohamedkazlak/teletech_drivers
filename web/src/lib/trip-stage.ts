import type { TripStage, TripSummary } from '../api/types'

export function tripStage(trip: Pick<TripSummary, 'status' | 'confirmation_status'>): TripStage {
  if (trip.status === 'completed') {
    return trip.confirmation_status === 'pending' ? 'awaiting_report' : 'completed'
  }
  if (trip.status === 'going' || trip.status === 'at_destination' || trip.status === 'returning') {
    return 'in_progress'
  }
  return trip.status
}
