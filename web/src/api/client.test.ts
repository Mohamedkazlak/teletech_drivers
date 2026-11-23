import { afterEach, describe, expect, it, vi } from 'vitest'
import { createApiClient, handlePasswordChangeRequired, handleUnauthorized } from './client'
import { ApiError } from './errors'
import { setNavigator } from './navigation'
import { sessionStore } from './session'

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

function clientWith(
  fetchImpl: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>,
  handlers?: { onUnauthorized?: () => void; onPasswordChangeRequired?: () => void },
) {
  return createApiClient({
    baseUrl: 'http://api.test/api',
    getToken: () => sessionStore.get(),
    fetchImpl,
    onUnauthorized: handlers?.onUnauthorized ?? vi.fn(),
    onPasswordChangeRequired: handlers?.onPasswordChangeRequired ?? vi.fn(),
  })
}

afterEach(() => {
  sessionStore.clear()
  setNavigator(null)
})

describe('api client errors', () => {
  it('attaches the bearer token and returns JSON', async () => {
    sessionStore.set('token-1')
    let init: RequestInit | undefined
    const fetchImpl = vi.fn(async (_input: RequestInfo | URL, next?: RequestInit) => {
      init = next
      return jsonResponse(200, { id: 'u1' })
    })
    const client = clientWith(fetchImpl)

    await expect(client.get('/auth/me')).resolves.toEqual({ id: 'u1' })
    const headers = new Headers(init?.headers)
    expect(headers.get('Authorization')).toBe('Bearer token-1')
    expect(headers.get('Accept')).toBe('application/json')
  })

  it('maps a 422 body onto ApiError.errors', async () => {
    const client = clientWith(async () =>
      jsonResponse(422, {
        message: 'The given data was invalid.',
        errors: { email: ['The email field is required.'] },
      }),
    )

    const error = await client.post('/auth/login', {}).catch((caught: unknown) => caught)
    expect(error).toBeInstanceOf(ApiError)
    expect(error).toMatchObject({
      status: 422,
      message: 'The given data was invalid.',
      errors: { email: ['The email field is required.'] },
    })
  })

  it('clears the session and redirects to login on 401', async () => {
    sessionStore.set('stale')
    const visited: string[] = []
    setNavigator((path) => {
      visited.push(path)
    })
    const client = clientWith(async () => jsonResponse(401, { message: 'Unauthenticated.' }), {
      onUnauthorized: handleUnauthorized,
    })

    await expect(client.get('/places')).rejects.toMatchObject({
      status: 401,
      message: 'Unauthenticated.',
    })
    expect(sessionStore.get()).toBeNull()
    expect(visited).toEqual(['/login'])
  })

  it('does not redirect when the caller opts out of auth handling', async () => {
    sessionStore.set('token-1')
    const onUnauthorized = vi.fn()
    const client = clientWith(async () => jsonResponse(401, { message: 'Invalid credentials.' }), {
      onUnauthorized,
    })

    await expect(
      client.post('/auth/login', { email: 'a@b.c', password: 'nope' }, { skipAuthRedirect: true }),
    ).rejects.toMatchObject({ status: 401 })
    expect(onUnauthorized).not.toHaveBeenCalled()
  })

  it('redirects to change-password on 403 password_change_required', async () => {
    sessionStore.set('token-1')
    const visited: string[] = []
    setNavigator((path) => {
      visited.push(path)
    })
    const onUnauthorized = vi.fn()
    const client = clientWith(
      async () =>
        jsonResponse(403, {
          message: 'You must change your password before continuing.',
          code: 'password_change_required',
        }),
      { onUnauthorized, onPasswordChangeRequired: handlePasswordChangeRequired },
    )

    await expect(client.get('/places')).rejects.toMatchObject({
      status: 403,
      code: 'password_change_required',
    })
    expect(sessionStore.get()).toBe('token-1')
    expect(onUnauthorized).not.toHaveBeenCalled()
    expect(visited).toEqual(['/change-password'])
  })

  it('keeps a 409 message without treating it as a password change', async () => {
    const onPasswordChangeRequired = vi.fn()
    const client = clientWith(
      async () => jsonResponse(409, { message: 'Trip request cannot be approved.' }),
      { onPasswordChangeRequired },
    )

    await expect(client.post('/trip-requests/1/approve')).rejects.toMatchObject({
      status: 409,
      message: 'Trip request cannot be approved.',
    })
    expect(onPasswordChangeRequired).not.toHaveBeenCalled()
  })

  it('turns a network failure into ApiError status 0', async () => {
    const client = clientWith(async () => {
      throw new TypeError('offline')
    })

    await expect(client.get('/places')).rejects.toMatchObject({
      status: 0,
      message: 'Network request failed.',
    })
  })
})
