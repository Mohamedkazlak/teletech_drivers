import type { PageLocation } from '../api/base-url'

export type ReverbConfig = {
  key: string
  host: string
  port: number
  scheme: 'http' | 'https'
}

type ReverbEnv = {
  VITE_REVERB_APP_KEY?: string
  VITE_REVERB_HOST?: string
  VITE_REVERB_PORT?: string
  VITE_REVERB_SCHEME?: string
}

/** Socket settings. An empty key means the site stays on polling only. */
export function resolveReverbConfig(env: ReverbEnv, page: PageLocation): ReverbConfig | null {
  const key = env.VITE_REVERB_APP_KEY?.trim() ?? ''
  if (key === '') return null

  const host = env.VITE_REVERB_HOST?.trim() || page.hostname
  const port = Number(env.VITE_REVERB_PORT ?? '8080')
  const scheme = env.VITE_REVERB_SCHEME?.trim() === 'https' ? 'https' : 'http'

  return {
    key,
    host,
    port: Number.isFinite(port) && port > 0 ? port : 8080,
    scheme,
  }
}
