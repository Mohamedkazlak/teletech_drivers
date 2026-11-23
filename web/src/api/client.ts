import { resolveApiBaseUrl } from './base-url'
import { ApiError, normalizeApiError } from './errors'
import { redirectTo } from './navigation'
import { sessionStore } from './session'

export type QueryParams = Record<string, string | number | boolean | null | undefined>

export type RequestOptions = {
  method?: string
  body?: unknown
  query?: QueryParams
  token?: string | null
  skipAuthRedirect?: boolean
  signal?: AbortSignal
}

export type ApiClient = {
  request<T>(path: string, options?: RequestOptions): Promise<T>
  get<T>(path: string, options?: Omit<RequestOptions, 'method' | 'body'>): Promise<T>
  post<T>(
    path: string,
    body?: unknown,
    options?: Omit<RequestOptions, 'method' | 'body'>,
  ): Promise<T>
  patch<T>(
    path: string,
    body?: unknown,
    options?: Omit<RequestOptions, 'method' | 'body'>,
  ): Promise<T>
  put<T>(
    path: string,
    body?: unknown,
    options?: Omit<RequestOptions, 'method' | 'body'>,
  ): Promise<T>
  delete<T>(path: string, options?: Omit<RequestOptions, 'method' | 'body'>): Promise<T>
}

export type ApiClientOptions = {
  baseUrl: string
  getToken: () => string | null
  fetchImpl?: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>
  onUnauthorized: () => void
  onPasswordChangeRequired: () => void
}

const PASSWORD_CHANGE_CODE = 'password_change_required'

export function createApiClient(options: ApiClientOptions): ApiClient {
  const fetchImpl = options.fetchImpl ?? fetch
  const baseUrl = options.baseUrl.replace(/\/$/, '')

  async function request<T>(path: string, requestOptions: RequestOptions = {}): Promise<T> {
    const headers = new Headers()
    headers.set('Accept', 'application/json')
    const explicitToken = requestOptions.token
    const token = explicitToken === undefined ? options.getToken() : explicitToken
    if (token) headers.set('Authorization', `Bearer ${token}`)

    const init: RequestInit = {
      method: requestOptions.method ?? 'GET',
      headers,
      signal: requestOptions.signal,
    }
    if (requestOptions.body !== undefined) {
      headers.set('Content-Type', 'application/json')
      init.body = JSON.stringify(requestOptions.body)
    }

    let response: Response
    try {
      response = await fetchImpl(`${baseUrl}${path}${toQuery(requestOptions.query)}`, init)
    } catch {
      throw new ApiError('Network request failed.', 0)
    }

    const body = await readBody(response)
    if (response.ok) return body as T

    const error = normalizeApiError(response.status, body)
    if (response.status === 401 && token && !requestOptions.skipAuthRedirect) {
      options.onUnauthorized()
    }
    if (
      response.status === 403 &&
      error.code === PASSWORD_CHANGE_CODE &&
      !requestOptions.skipAuthRedirect
    ) {
      options.onPasswordChangeRequired()
    }
    throw error
  }

  return {
    request,
    get: (path, requestOptions) => request(path, { ...requestOptions, method: 'GET' }),
    post: (path, body, requestOptions) =>
      request(path, { ...requestOptions, method: 'POST', body }),
    patch: (path, body, requestOptions) =>
      request(path, { ...requestOptions, method: 'PATCH', body }),
    put: (path, body, requestOptions) => request(path, { ...requestOptions, method: 'PUT', body }),
    delete: (path, requestOptions) => request(path, { ...requestOptions, method: 'DELETE' }),
  }
}

export function handleUnauthorized(): void {
  sessionStore.clear()
  redirectTo('/login')
}

export function handlePasswordChangeRequired(): void {
  redirectTo('/change-password')
}

function currentPage(): { protocol: string; hostname: string } {
  if (typeof window === 'undefined') {
    return { protocol: 'http:', hostname: '127.0.0.1' }
  }
  return { protocol: window.location.protocol, hostname: window.location.hostname }
}

export const api = createApiClient({
  baseUrl: resolveApiBaseUrl(import.meta.env.VITE_API_BASE_URL, currentPage()),
  getToken: () => sessionStore.get(),
  onUnauthorized: handleUnauthorized,
  onPasswordChangeRequired: handlePasswordChangeRequired,
})

function toQuery(query: QueryParams | undefined): string {
  if (!query) return ''
  const params = new URLSearchParams()
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null || value === '') continue
    params.set(key, String(value))
  }
  const text = params.toString()
  return text ? `?${text}` : ''
}

async function readBody(response: Response): Promise<unknown> {
  const text = await response.text()
  if (!text) return null
  try {
    return JSON.parse(text) as unknown
  } catch {
    return { message: text }
  }
}
