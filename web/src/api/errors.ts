export class ApiError extends Error {
  readonly status: number
  readonly code?: string
  readonly errors?: Record<string, string[]>

  constructor(
    message: string,
    status: number,
    details?: { code?: string; errors?: Record<string, string[]> },
  ) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.code = details?.code
    this.errors = details?.errors
  }
}

export function isApiError(error: unknown): error is ApiError {
  return error instanceof ApiError
}

export function normalizeApiError(status: number, body: unknown): ApiError {
  const record = isRecord(body) ? body : {}
  const message =
    typeof record.message === 'string' && record.message.trim() !== ''
      ? record.message
      : `Request failed (${status})`
  const code = typeof record.code === 'string' ? record.code : undefined
  const errors = normalizeErrors(record.errors)
  return new ApiError(message, status, { code, errors })
}

function normalizeErrors(value: unknown): Record<string, string[]> | undefined {
  if (!isRecord(value)) return undefined
  const errors: Record<string, string[]> = {}
  for (const [key, messages] of Object.entries(value)) {
    if (Array.isArray(messages) && messages.every((item) => typeof item === 'string')) {
      errors[key] = messages
    }
  }
  return Object.keys(errors).length > 0 ? errors : undefined
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}
