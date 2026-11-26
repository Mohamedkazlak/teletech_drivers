import { useCallback, useSyncExternalStore } from 'react'

/** Live media query match; false where matchMedia is missing (tests, old browsers). */
export function useMediaQuery(query: string): boolean {
  const subscribe = useCallback(
    (onChange: () => void) => {
      if (typeof window.matchMedia !== 'function') return () => {}
      const list = window.matchMedia(query)
      // Safari before 14 only has the older addListener API.
      if (typeof list.addEventListener === 'function') {
        list.addEventListener('change', onChange)
        return () => list.removeEventListener('change', onChange)
      }
      list.addListener(onChange)
      return () => list.removeListener(onChange)
    },
    [query],
  )
  const snapshot = () =>
    typeof window.matchMedia === 'function' ? window.matchMedia(query).matches : false
  return useSyncExternalStore(subscribe, snapshot, () => false)
}
