import { useCallback, useMemo, useState, type ReactNode } from 'react'
import StatusMark from '../reactbits/StatusMark'
import { InfoIcon } from '../icons'
import { ToastContext, type ToastTone } from './toast-context'

type ToastItem = {
  id: string
  message: string
  tone: ToastTone
  leaving: boolean
}

const VISIBLE_MS = 4000
const EXIT_MS = 180

/*
  Navy toasts (same as the app's snackbars). Success and error draw their
  mark with React Bits' StatusMark; they slide up in and fade out faster
  than they came.
*/
export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([])

  const push = useCallback((message: string, tone: ToastTone = 'info') => {
    const id = crypto.randomUUID()
    setToasts((current) => [...current, { id, message, tone, leaving: false }])
    window.setTimeout(() => {
      setToasts((current) =>
        current.map((item) => (item.id === id ? { ...item, leaving: true } : item)),
      )
      window.setTimeout(() => {
        setToasts((current) => current.filter((item) => item.id !== id))
      }, EXIT_MS)
    }, VISIBLE_MS)
  }, [])

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
            role="status"
            className={`pointer-events-auto flex items-center gap-3 rounded-[14px] bg-navy px-3.5 py-3 text-sm text-white shadow-float ring-1 ring-white/10 transition-[opacity,transform] duration-[180ms] ease-[var(--ease-out)] animate-rise ${
              toast.leaving ? 'translate-y-1 opacity-0' : ''
            }`}
          >
            <span aria-hidden="true" className="inline-flex shrink-0">
              {toast.tone === 'info' ? (
                <InfoIcon size={22} className="text-[#8fb9ff]" />
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
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  )
}
