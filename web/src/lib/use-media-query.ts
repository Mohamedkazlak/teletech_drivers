import { useCallback, useSyncExternalStore } from 'react'

/** Live media query match; false where matchMedia is missing (tests, old browsers). */
export function useMediaQuery(query: string): boolean {
  const subscribe = useCallback(
    (onChange: () => void) => {
      if (typeof window.matchMedia !== 'function') return () => {}
      const list = window.matchMedia(query)
      list.addEventListener('change', onChange)
      return () => list.removeEventListener('change', onChange)
    },
    [query],
  )
  const snapshot = () =>
    typeof window.matchMedia === 'function' ? window.matchMedia(query).matches : false
  return useSyncExternalStore(subscribe, snapshot, () => false)
}
