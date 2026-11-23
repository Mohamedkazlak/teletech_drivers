import type { RequestTrackingStage } from '../api/types'

/** Maps the derived stage onto the My Trips chip vocabulary. */
export function trackingChipStatus(stage: RequestTrackingStage): string {
  switch (stage) {
    case 'submitted':
      return 'pending'
    case 'approved':
      return 'approved'
    case 'driver_assigned':
      return 'driver_assigned'
    case 'in_progress':
      return 'in_progress'
    case 'finished':
    case 'awaiting_confirmation':
    case 'confirmed':
    case 'unconfirmed':
      return 'completed'
    case 'rejected':
      return 'rejected'
    case 'cancelled':
      return 'cancelled'
  }
}
