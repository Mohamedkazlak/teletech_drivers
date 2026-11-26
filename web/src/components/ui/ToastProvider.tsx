import { useCallback, useMemo, useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import StatusMark from '../reactbits/StatusMark'
import { CloseIcon, InfoIcon } from '../icons'
import { ToastContext, type ToastAction, type ToastTone } from './toast-context'

type ToastItem = {
  id: string
  message: string
  tone: ToastTone
  action?: ToastAction
  leaving: boolean
}

const VISIBLE_MS = 4000
const EXIT_MS = 180

/*
  Navy toasts (same as the app's snackbars). Success and error draw their
  mark with React Bits' StatusMark; they slide up in and fade out faster
  than they came. Errors stay until closed, so nobody misses them.
*/
export function ToastProvider({ children }: { children: ReactNode }) {
  const { t } = useTranslation()
  const [toasts, setToasts] = useState<ToastItem[]>([])

  const dismiss = useCallback((id: string) => {
    setToasts((current) =>
      current.map((item) => (item.id === id ? { ...item, leaving: true } : item)),
    )
    window.setTimeout(() => {
      setToasts((current) => current.filter((item) => item.id !== id))
    }, EXIT_MS)
  }, [])

  const push = useCallback(
    (message: string, tone: ToastTone = 'info', options?: { action?: ToastAction }) => {
      const id = crypto.randomUUID()
      setToasts((current) => {
        const next = [...current, { id, message, tone, action: options?.action, leaving: false }]
        // Errors stay until closed; keep only the latest three so repeats don't pile up.
        const errors = next.filter((item) => item.tone === 'error')
        const drop = new Set(errors.slice(0, Math.max(0, errors.length - 3)).map((item) => item.id))
        return next.filter((item) => !drop.has(item.id))
      })
      if (tone !== 'error') window.setTimeout(() => dismiss(id), VISIBLE_MS)
    },
    [dismiss],
  )

  const value = useMemo(() => push, [push])

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div
        aria-live="polite"
        className="pointer-events-none fixed bottom-5 end-5 z-50 flex w-[22rem] max-w-[calc(100vw-2.5rem)] flex-col gap-2"
      >
        {toasts.map((toast) => (
          <div
            key={toast.id}
            role={toast.tone === 'error' ? 'alert' : 'status'}
            className={`pointer-events-auto flex items-center gap-3 rounded-[14px] bg-navy px-3.5 py-3 text-sm text-white shadow-float ring-1 ring-white/10 transition-[opacity,transform] duration-[180ms] ease-[var(--ease-out)] animate-rise ${
              toast.leaving ? 'translate-y-1 opacity-0' : ''
            }`}
          >
            <span aria-hidden="true" className="inline-flex shrink-0">
              {toast.tone === 'info' ? (
                <InfoIcon size={22} className="text-[var(--color-toast-accent)]" />
              ) : (
                <StatusMark
                  status={toast.tone === 'success' ? 'done' : 'failed'}
                  size={22}
                  color="#8fb9ff"
                  doneColor="#4fd19a"
                  errorColor="#ff8a8a"
                />
              )}
            </span>
            <span className="min-w-0 flex-1 leading-snug">{toast.message}</span>
            {toast.action ? (
              <button
                type="button"
                className="shrink-0 rounded-[8px] px-2 py-1 text-sm font-semibold text-[var(--color-toast-accent)] transition-colors duration-150 hover:bg-white/10"
                onClick={() => {
                  toast.action?.onClick()
                  dismiss(toast.id)
                }}
              >
                {toast.action.label}
              </button>
            ) : null}
            {toast.tone === 'error' ? (
              <button
                type="button"
                aria-label={t('common.close')}
                className="-me-1 inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-[8px] text-white/70 transition-colors duration-150 hover:bg-white/10 hover:text-white"
                onClick={() => dismiss(toast.id)}
              >
                <CloseIcon size={16} />
              </button>
            ) : null}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  )
}
