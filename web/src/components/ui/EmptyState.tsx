import { Link } from 'react-router-dom'
import { ghostButtonClass } from './styles'

export type EmptyStateAction = {
  label: string
  onClick?: () => void
  to?: string
}

type EmptyStateProps = {
  message: string
  action?: EmptyStateAction
}

/** The route drawing, a one-line reason, and the next step when there is one. */
export function EmptyState({ message, action }: EmptyStateProps) {
  return (
    <div className="mx-auto flex max-w-sm flex-col items-center gap-3 text-center text-ink-muted">
      <EmptyRoute />
      <p>{message}</p>
      {action?.to ? (
        <Link to={action.to} className={ghostButtonClass}>
          {action.label}
        </Link>
      ) : action ? (
        <button type="button" className={ghostButtonClass} onClick={action.onClick}>
          {action.label}
        </button>
      ) : null}
    </div>
  )
}

/** Origin dot → dashed route → destination ring; mirrors in Arabic. */
function EmptyRoute() {
  return (
    <svg
      width="72"
      height="52"
      viewBox="0 0 132 96"
      fill="none"
      aria-hidden="true"
      className="rtl:-scale-x-100"
    >
      <circle cx="114" cy="23" r="22" fill="var(--color-pale)" />
      <path
        d="M16 75 C66 98 58 2 114 23"
        stroke="var(--color-line)"
        strokeWidth="4"
        strokeLinecap="round"
      />
      <path
        d="M16 75 C66 98 58 2 114 23"
        stroke="var(--color-deep)"
        strokeWidth="4"
        strokeLinecap="round"
        strokeDasharray="6 10"
        opacity="0.5"
      />
      <circle cx="16" cy="75" r="6" fill="var(--color-deep)" />
      <circle cx="114" cy="23" r="7" fill="white" stroke="var(--color-deep)" strokeWidth="4" />
    </svg>
  )
}
