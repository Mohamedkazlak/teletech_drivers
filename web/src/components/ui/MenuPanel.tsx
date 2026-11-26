import { forwardRef, type CSSProperties, type KeyboardEventHandler, type ReactNode } from 'react'

type MenuPanelProps = {
  /** Which side of the trigger the panel lines up with, in reading direction. */
  align?: 'end' | 'start'
  /** Opens above the trigger when there is no room below. */
  placement?: 'below' | 'above'
  className?: string
  style?: CSSProperties
  children: ReactNode
  role?: string
  id?: string
  'aria-label'?: string
  onKeyDown?: KeyboardEventHandler<HTMLDivElement>
}

/*
  Floating menu surface. It grows from the trigger's corner (scale 0.95 with a
  fade, 180 ms ease-out) and simply unmounts on close, so closing is instant.
*/
export const MenuPanel = forwardRef<HTMLDivElement, MenuPanelProps>(function MenuPanel(
  { align = 'end', placement = 'below', className = '', children, ...rest },
  ref,
) {
  const origin =
    placement === 'below'
      ? align === 'end'
        ? 'origin-top-right rtl:origin-top-left'
        : 'origin-top-left rtl:origin-top-right'
      : align === 'end'
        ? 'origin-bottom-right rtl:origin-bottom-left'
        : 'origin-bottom-left rtl:origin-bottom-right'
  return (
    <div
      ref={ref}
      {...rest}
      className={`z-40 rounded-[14px] border border-line bg-white p-1.5 shadow-float animate-menu-in ${origin} ${className}`}
    >
      {children}
    </div>
  )
})
