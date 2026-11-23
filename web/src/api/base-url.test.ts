import { describe, expect, it } from 'vitest'
import { resolveApiBaseUrl } from './base-url'

describe('resolveApiBaseUrl', () => {
  const page = { protocol: 'http:', hostname: '192.168.1.20' }

  it('uses a configured absolute URL', () => {
    expect(resolveApiBaseUrl('http://127.0.0.1:8000/api', page)).toBe('http://127.0.0.1:8000/api')
  })

  it('strips a trailing slash from a configured URL', () => {
    expect(resolveApiBaseUrl('http://127.0.0.1:8000/api/', page)).toBe('http://127.0.0.1:8000/api')
  })

  it('follows the page host when the env value is unset or blank', () => {
    expect(resolveApiBaseUrl(undefined, page)).toBe('http://192.168.1.20:8000/api')
    expect(resolveApiBaseUrl('  ', page)).toBe('http://192.168.1.20:8000/api')
  })

  it('keeps https when the page is https', () => {
    expect(resolveApiBaseUrl(undefined, { protocol: 'https:', hostname: '10.0.0.8' })).toBe(
      'https://10.0.0.8:8000/api',
    )
  })

  it('adds a colon when the protocol has none', () => {
    expect(resolveApiBaseUrl(undefined, { protocol: 'http', hostname: 'localhost' })).toBe(
      'http://localhost:8000/api',
    )
  })
})
