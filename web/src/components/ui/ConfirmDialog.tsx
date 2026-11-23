import type { ReactNode } from 'react'
import { useId } from 'react'
import { dangerButtonClass, primaryButtonClass, secondaryButtonClass } from './styles'
import { useDialogKey } from './use-dialog'

type ConfirmDialogProps = {
  open: boolean
  title: string
  description: string
  confirmLabel: string
  cancelLabel: string
  tone?: 'default' | 'danger'
  confirmDisabled?: boolean
  busy?: boolean
  onConfirm: () => void
  onCancel: () => void
  children?: ReactNode
}

export function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel,
  cancelLabel,
  tone = 'default',
  confirmDisabled = false,
  busy = false,
  onConfirm,
  onCancel,
  children,
}: ConfirmDialogProps) {
  const titleId = useId()
  const dialogRef = useDialogKey(open, onCancel)

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <button
        type="button"
        className="absolute inset-0 bg-navy/50"
        aria-label={cancelLabel}
        onClick={onCancel}
      />
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="relative w-full max-w-md rounded-card bg-white p-5 shadow-dialog"
      >
        <h2 id={titleId} className="text-lg font-bold text-navy">
          {title}
        </h2>
        <p className="mt-2 text-sm text-navy/75">{description}</p>
        {children ? <div className="mt-4">{children}</div> : null}
        <div className="mt-5 flex justify-end gap-2">
          <button type="button" className={secondaryButtonClass} onClick={onCancel} disabled={busy}>
            {cancelLabel}
          </button>
          <button
            type="button"
            autoFocus={children == null}
            className={tone === 'danger' ? dangerButtonClass : primaryButtonClass}
            disabled={confirmDisabled || busy}
            onClick={onConfirm}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  )
}
