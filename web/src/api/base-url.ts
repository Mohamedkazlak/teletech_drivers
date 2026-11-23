export type PageLocation = {
  protocol: string
  hostname: string
}

/** Uses VITE_API_BASE_URL, or the page host on port 8000 when that variable is unset. */
export function resolveApiBaseUrl(configured: string | undefined, page: PageLocation): string {
  const explicit = configured?.trim() ?? ''
  if (explicit !== '') return explicit.replace(/\/+$/, '')

  const protocol = page.protocol.endsWith(':') ? page.protocol : `${page.protocol}:`
  return `${protocol}//${page.hostname}:8000/api`
}
