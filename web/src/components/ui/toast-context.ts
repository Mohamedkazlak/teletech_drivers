import { createContext, useContext } from 'react'

export type ToastTone = 'success' | 'error' | 'info'

export type ToastAction = { label: string; onClick: () => void }

export type ToastApi = (
  message: string,
  tone?: ToastTone,
  options?: { action?: ToastAction },
) => void

export const ToastContext = createContext<ToastApi | null>(null)

export function useToast(): ToastApi {
  const value = useContext(ToastContext)
  if (!value) throw new Error('useToast must be used within ToastProvider')
  return value
}
