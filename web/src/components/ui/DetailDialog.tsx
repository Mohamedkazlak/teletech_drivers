import type { ReactNode } from 'react'
import { useId } from 'react'
import { useTranslation } from 'react-i18next'
import { secondaryButtonClass } from './styles'
import { useDialogKey } from './use-dialog'

type DetailDialogProps = {
  open: boolean
  title: string
  onClose: () => void
  children: ReactNode
}

export function DetailDialog({ open, title, onClose, children }: DetailDialogProps) {
  const { t } = useTranslation()
  const titleId = useId()
  const dialogRef = useDialogKey(open, onClose)

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <button
        type="button"
        className="absolute inset-0 bg-navy/50"
        aria-label={t('common.close')}
        onClick={onClose}
      />
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="relative flex max-h-[90dvh] w-full max-w-3xl flex-col overflow-hidden rounded-card bg-white shadow-dialog"
      >
        <div className="flex items-start justify-between gap-3 border-b border-pale px-5 py-4">
          <h2 id={titleId} className="text-lg font-bold text-navy">
            {title}
          </h2>
          <button type="button" className={secondaryButtonClass} onClick={onClose} autoFocus>
            {t('common.close')}
          </button>
        </div>
        <div className="overflow-y-auto px-5 py-4">{children}</div>
      </div>
    </div>
  )
}
