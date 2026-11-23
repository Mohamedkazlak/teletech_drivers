import type { TFunction } from 'i18next'
import { ApiError } from '../api/errors'

export function messageForApiError(error: unknown, t: TFunction): string {
  if (!(error instanceof ApiError)) return t('common.network')
  if (error.status === 0) return t('common.network')
  const general = error.errors?.general?.[0]
  if (general) return general
  if (error.message.trim() !== '') return error.message
  if (error.status === 403) return t('errors.forbidden')
  if (error.status === 404) return t('errors.notFound')
  if (error.status === 409) return t('errors.conflict')
  return t('common.error')
}

export function firstFieldError(error: unknown, field: string): string | undefined {
  if (!(error instanceof ApiError)) return undefined
  return error.errors?.[field]?.[0]
}
