/*
  Shared control styles. Motion follows the app: presses scale to 0.97 in
  120 ms; colour and border changes use the strong ease-out curve.
*/

const pressable =
  'transition-[background-color,border-color,color,box-shadow,transform,opacity] duration-150 ease-[var(--ease-out)] active:scale-[0.97] disabled:active:scale-100 disabled:cursor-not-allowed'

const buttonBase = `inline-flex h-[var(--control-height)] select-none items-center justify-center gap-2 rounded-control px-4 text-sm font-semibold whitespace-nowrap ${pressable}`

export const controlClass =
  'h-[var(--control-height)] w-full rounded-control border border-line bg-white px-3.5 text-[15px] text-navy shadow-[0_1px_0_rgb(11_31_69/0.03)] outline-none transition-[border-color,box-shadow,background-color] duration-150 ease-[var(--ease-out)] placeholder:text-ink-muted/70 hover:border-light focus:border-deep focus:shadow-[0_0_0_4px_rgb(47_123_234/0.16)] disabled:cursor-not-allowed disabled:bg-scaffold disabled:text-ink-muted aria-[invalid=true]:border-danger aria-[invalid=true]:focus:shadow-[0_0_0_4px_rgb(214_69_69/0.14)]'

export const primaryButtonClass = `${buttonBase} bg-deep text-white shadow-button hover:bg-[#0a438d] disabled:bg-light/60 disabled:shadow-none`

export const secondaryButtonClass = `${buttonBase} border border-line bg-white text-navy hover:border-light hover:bg-pale/60 disabled:opacity-55`

export const dangerButtonClass = `${buttonBase} bg-danger text-white shadow-[0_2px_8px_rgb(214_69_69/0.25)] hover:bg-danger-ink disabled:opacity-55`

export const dangerQuietButtonClass = `${buttonBase} border border-danger/30 bg-white text-danger-ink hover:border-danger/50 hover:bg-danger/8 disabled:opacity-55`

/** Small inline button (table rows, toolbars). */
export const ghostButtonClass = `inline-flex h-9 select-none items-center justify-center gap-1.5 rounded-[10px] px-3 text-sm font-semibold text-deep hover:bg-pale ${pressable}`

export const cardClass = 'rounded-card border border-line bg-white text-navy'

export const alertClass =
  'flex items-start gap-2 rounded-control border border-danger/25 bg-danger/8 px-3 py-2.5 text-sm text-danger-ink animate-pop'

/** Square icon-only button for the top bar. Give it an aria-label. */
export const iconButtonClass = `relative inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-[12px] border border-line bg-white text-navy hover:border-light hover:bg-pale/60 ${pressable}`

/** Floating menu panel (account, notifications). */
export const menuPanelClass =
  'absolute end-0 z-30 mt-2 origin-top-right rounded-[14px] border border-line bg-white p-1.5 shadow-float animate-pop rtl:origin-top-left'

export const menuItemClass =
  'flex w-full items-center gap-2.5 rounded-[10px] px-3 py-2 text-start text-sm text-navy transition-colors duration-150 hover:bg-pale'
