import type { DriverRecommendation } from '../api/types'

/**
 * Recommended drivers are the ones the API does not flag for confirmation.
 * Unavailable drivers stay in the list so the picker can disable them.
 * Order within each group is the API order (tier, then trips this week, then name).
 */
export function orderedRecommendations(
  items: DriverRecommendation[],
  excludeDriverId?: string | null,
): { recommended: DriverRecommendation[]; others: DriverRecommendation[] } {
  const visible =
    excludeDriverId == null ? items : items.filter((item) => item.driver.id !== excludeDriverId)
  return {
    recommended: visible.filter((item) => !item.needs_confirmation && !item.is_unavailable),
    others: visible.filter((item) => item.needs_confirmation || item.is_unavailable),
  }
}
