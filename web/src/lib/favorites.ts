export const MAX_FAVORITE_PLACES = 5

export function limitFavoriteIds(ids: string[]): string[] {
  const unique: string[] = []
  for (const id of ids) {
    if (!id || unique.includes(id)) continue
    unique.push(id)
    if (unique.length >= MAX_FAVORITE_PLACES) break
  }
  return unique
}
