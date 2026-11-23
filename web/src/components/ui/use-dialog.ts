import { useEffect, useRef } from 'react'

function focusable(node: HTMLElement): HTMLElement[] {
  return Array.from(
    node.querySelectorAll<HTMLElement>(
      'button:not(:disabled), [href], input:not(:disabled), select:not(:disabled), textarea:not(:disabled), [tabindex]:not([tabindex="-1"])',
    ),
  )
}

export function useDialogKey(open: boolean, onClose: () => void) {
  const ref = useRef<HTMLDivElement>(null)
  const onCloseRef = useRef(onClose)

  useEffect(() => {
    onCloseRef.current = onClose
  }, [onClose])

  useEffect(() => {
    if (!open) return
    const previous = document.activeElement instanceof HTMLElement ? document.activeElement : null

    function onKey(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        event.preventDefault()
        onCloseRef.current()
        return
      }
      if (event.key !== 'Tab') return
      const node = ref.current
      if (!node) return
      const items = focusable(node)
      if (items.length === 0) return
      const first = items[0]
      const last = items[items.length - 1]
      const active = document.activeElement
      const inside = active instanceof Node && node.contains(active)
      if (event.shiftKey && (active === first || !inside)) {
        event.preventDefault()
        last?.focus()
      } else if (!event.shiftKey && (active === last || !inside)) {
        event.preventDefault()
        first?.focus()
      }
    }

    document.addEventListener('keydown', onKey)
    const frame = window.requestAnimationFrame(() => {
      const node = ref.current
      if (!node) return
      const active = document.activeElement
      if (active instanceof Node && node.contains(active)) return
      focusable(node)[0]?.focus()
    })
    return () => {
      window.cancelAnimationFrame(frame)
      document.removeEventListener('keydown', onKey)
      previous?.focus()
    }
  }, [open])

  return ref
}
