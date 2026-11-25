import type { ReactNode } from 'react'
import { useId } from 'react'
import { useTranslation } from 'react-i18next'
import { CloseIcon } from '../icons'
import { iconButtonClass } from './styles'
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
        className="absolute inset-0 bg-navy-deep/45 backdrop-blur-[2px] animate-fade"
        aria-label={t('common.close')}
        onClick={onClose}
      />
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="relative flex max-h-[90dvh] w-full max-w-3xl flex-col overflow-hidden rounded-[20px] bg-white shadow-dialog animate-pop"
      >
        <div className="flex items-center justify-between gap-3 border-b border-line px-6 py-4">
          <h2 id={titleId} className="text-lg font-semibold tracking-[-0.01em] text-navy">
            {title}
          </h2>
          <button
            type="button"
            className={iconButtonClass}
            onClick={onClose}
            aria-label={t('common.close')}
            autoFocus
          >
            <CloseIcon size={18} />
          </button>
        </div>
        <div className="overflow-y-auto px-6 py-5">{children}</div>
      </div>
    </div>
  )
}
