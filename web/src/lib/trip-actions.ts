import type { TripStatus } from '../api/types'

const IN_PROGRESS: readonly TripStatus[] = ['going', 'at_destination', 'returning']

export function isTripInProgress(status: TripStatus | undefined): boolean {
  return status != null && IN_PROGRESS.some((item) => item === status)
}

/** POST /trips/{id}/assign from unassigned. */
export function canAssignDriver(status: TripStatus): boolean {
  return status === 'unassigned'
}

/** POST /trips/{id}/assign while the trip is still assigned. */
export function canReassignDriver(status: TripStatus): boolean {
  return status === 'assigned'
}

/** POST /trips/{id}/cancel. In-progress and finished trips are rejected with 409. */
export function canCancelTrip(status: TripStatus): boolean {
  return status === 'unassigned' || status === 'assigned'
}
