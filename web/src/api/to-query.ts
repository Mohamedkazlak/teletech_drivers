import type { QueryParams } from './client'

export const PAGE_SIZE = 15

export function toQuery(query: object): QueryParams {
  const params: QueryParams = {}
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null || value === '') continue
    if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
      params[key] = value
    }
  }
  return params
}
