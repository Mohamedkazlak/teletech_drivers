import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useLocation, useNavigate, useNavigationType } from 'react-router-dom'

type Trail = {
  keys: string[]
  index: number
}

/**
 * Tracks in-app history so the control only appears when a previous page exists.
 * Browser back would otherwise leave the console on the first page.
 */
function useCanGoBack(): boolean {
  const location = useLocation()
  const action = useNavigationType()
  const trail = useRef<Trail | null>(null)
  const applied = useRef<string | null>(null)
  const [index, setIndex] = useState(0)

  if (trail.current === null) {
    trail.current = { keys: [location.key], index: 0 }
  }

  useEffect(() => {
    const token = `${action}:${location.key}`
    if (applied.current === token) return
    applied.current = token

    const history = trail.current
    if (!history) return

    if (action === 'PUSH') {
      history.keys = history.keys.slice(0, history.index + 1)
      history.keys.push(location.key)
      history.index = history.keys.length - 1
    } else if (action === 'REPLACE') {
      history.keys[history.index] = location.key
    } else {
      const found = history.keys.lastIndexOf(location.key)
      if (found >= 0) {
        history.index = found
      } else {
        history.keys = [location.key]
        history.index = 0
      }
    }

    setIndex(history.index)
  }, [action, location.key])

  return index > 0
}

export function BackArrow({ className = 'h-5 w-5' }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={`${className} rtl:-scale-x-100`}
      aria-hidden="true"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M15 5 L8 12 L15 19" />
    </svg>
  )
}

export function BackButton() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const canGoBack = useCanGoBack()

  if (!canGoBack) return null

  return (
    <button
      type="button"
      className="inline-flex h-10 w-10 items-center justify-center rounded-control border-[1.5px] border-mid text-deep"
      aria-label={t('common.back')}
      onClick={() => navigate(-1)}
    >
      <BackArrow />
    </button>
  )
}
