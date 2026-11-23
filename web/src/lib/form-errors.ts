import type { FieldPath, FieldValues, UseFormSetError } from 'react-hook-form'
import { ApiError } from '../api/errors'

export function applyFieldErrors<T extends FieldValues>(
  error: unknown,
  setError: UseFormSetError<T>,
  fields: Array<FieldPath<T>>,
): string | null {
  if (!(error instanceof ApiError)) return null
  let banner: string | null = error.message
  if (!error.errors) return banner
  for (const [key, messages] of Object.entries(error.errors)) {
    const message = messages[0]
    if (!message) continue
    if (fields.includes(key as FieldPath<T>)) {
      setError(key as FieldPath<T>, { message })
      banner = null
    } else if (key === 'general') {
      banner = message
    }
  }
  return banner
}
