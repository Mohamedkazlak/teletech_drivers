import {
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type CSSProperties,
  type KeyboardEvent,
  type ReactNode,
} from 'react'
import { createPortal } from 'react-dom'
import { MoreIcon } from '../icons'
import { MenuPanel } from './MenuPanel'

export type RowActionItem = {
  label: string
  onSelect: () => void
  danger?: boolean
  disabled?: boolean
}

type RowActionsProps = {
  /** Accessible name for the "⋯" button, e.g. "Actions for Nader Ali". */
  label: string
  items: RowActionItem[]
  /** At most one visible action shown before the "⋯" button. */
  primary?: ReactNode
}

const MENU_WIDTH = 192
const MENU_ROOM = 220

/*
  "⋯" menu for a table row. It renders in a portal so the table's scroll box
  can't clip it, opens upward near the bottom of the screen, and supports
  arrow keys, Home/End, Escape and outside clicks.
*/
export function RowActions({ label, items, primary }: RowActionsProps) {
  const menuId = useId()
  const triggerRef = useRef<HTMLButtonElement>(null)
  const menuRef = useRef<HTMLDivElement>(null)
  const [open, setOpen] = useState(false)
  const [position, setPosition] = useState<{ style: CSSProperties; above: boolean } | null>(null)

  useLayoutEffect(() => {
    if (!open || !triggerRef.current) return
    const rect = triggerRef.current.getBoundingClientRect()
    const rtl = getComputedStyle(triggerRef.current).direction === 'rtl'
    const above = window.innerHeight - rect.bottom < MENU_ROOM && rect.top > MENU_ROOM
    const style: CSSProperties = {
      position: 'fixed',
      width: MENU_WIDTH,
      ...(above ? { bottom: window.innerHeight - rect.top + 6 } : { top: rect.bottom + 6 }),
      ...(rtl ? { left: rect.left } : { right: window.innerWidth - rect.right }),
    }
    setPosition({ style, above })
  }, [open])

  useEffect(() => {
    if (!open) return
    menuRef.current?.querySelector<HTMLButtonElement>('[role="menuitem"]:not(:disabled)')?.focus()
    function onPointerDown(event: PointerEvent) {
      const target = event.target as Node
      if (menuRef.current?.contains(target) || triggerRef.current?.contains(target)) return
      setOpen(false)
    }
    function onViewportChange() {
      const hadFocus = menuRef.current?.contains(document.activeElement) ?? false
      setOpen(false)
      if (hadFocus) triggerRef.current?.focus()
    }
    document.addEventListener('pointerdown', onPointerDown)
    window.addEventListener('resize', onViewportChange)
    window.addEventListener('scroll', onViewportChange, true)
    return () => {
      document.removeEventListener('pointerdown', onPointerDown)
      window.removeEventListener('resize', onViewportChange)
      window.removeEventListener('scroll', onViewportChange, true)
    }
  }, [open, position])

  function close(returnFocus: boolean) {
    setOpen(false)
    if (returnFocus) triggerRef.current?.focus()
  }

  function onMenuKeyDown(event: KeyboardEvent<HTMLDivElement>) {
    const enabled = Array.from(
      menuRef.current?.querySelectorAll<HTMLButtonElement>('[role="menuitem"]:not(:disabled)') ??
        [],
    )
    const index = enabled.indexOf(document.activeElement as HTMLButtonElement)
    let next = -1
    if (event.key === 'ArrowDown') next = (index + 1) % enabled.length
    else if (event.key === 'ArrowUp') next = (index - 1 + enabled.length) % enabled.length
    else if (event.key === 'Home') next = 0
    else if (event.key === 'End') next = enabled.length - 1
    else if (event.key === 'Escape') {
      event.preventDefault()
      close(true)
      return
    } else if (event.key === 'Tab') {
      // The menu lives in a portal at the end of the page, so let focus go
      // back to the row instead of jumping out of the table.
      event.preventDefault()
      close(true)
      return
    }
    if (next < 0) return
    event.preventDefault()
    enabled[next]?.focus()
  }

  if (items.length === 0) {
    return primary ? (
      <div data-row-actions="" className="flex items-center justify-end gap-1">
        {primary}
      </div>
    ) : null
  }

  return (
    <div data-row-actions="" className="flex items-center justify-end gap-1">
      {primary}
      <button
        ref={triggerRef}
        type="button"
        aria-label={label}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={open ? menuId : undefined}
        onClick={() => setOpen((value) => !value)}
        onKeyDown={(event) => {
          if (event.key === 'ArrowDown' && !open) {
            event.preventDefault()
            setOpen(true)
          }
        }}
        className={`inline-flex h-10 w-10 items-center justify-center rounded-[10px] text-ink-muted transition-[background-color,color,transform] duration-150 ease-[var(--ease-out)] hover:bg-pale hover:text-navy active:scale-[0.97] ${
          open ? 'bg-pale text-navy' : ''
        }`}
      >
        <MoreIcon size={20} />
      </button>
      {open && position
        ? createPortal(
            <MenuPanel
              ref={menuRef}
              id={menuId}
              role="menu"
              aria-label={label}
              data-row-actions=""
              placement={position.above ? 'above' : 'below'}
              style={position.style}
              onKeyDown={onMenuKeyDown}
            >
              {items.map((item) => (
                <button
                  key={item.label}
                  type="button"
                  role="menuitem"
                  disabled={item.disabled}
                  onClick={() => {
                    close(true)
                    item.onSelect()
                  }}
                  className={`flex w-full items-center rounded-[10px] px-3 py-2.5 text-start text-sm font-medium transition-colors duration-150 outline-none focus-visible:bg-pale disabled:cursor-not-allowed disabled:opacity-50 ${
                    item.danger
                      ? 'text-danger-ink hover:bg-danger/8 focus-visible:bg-danger/8'
                      : 'text-navy hover:bg-pale'
                  }`}
                >
                  {item.label}
                </button>
              ))}
            </MenuPanel>,
            document.body,
          )
        : null}
    </div>
  )
}
