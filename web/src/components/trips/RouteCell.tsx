import { useTranslation } from 'react-i18next'
import { formatDateTime } from '../../lib/format'

type RouteCellProps = {
  from: string | null | undefined
  to: string | null | undefined
  when?: string | null
}

/*
  The trip as a route: origin dot → dashed line → destination ring, with the
  time underneath. Only the drawing mirrors in Arabic; names stay readable.
*/
export function RouteCell({ from, to, when }: RouteCellProps) {
  const { t, i18n } = useTranslation()
  const dash = t('common.dash')
  const origin = from?.trim() || dash
  const destination = to?.trim() || dash

  return (
    <span className="flex min-w-0 max-w-[22rem] flex-col gap-1">
      <span className="flex min-w-0 items-center gap-2">
        <span aria-hidden="true" className="size-2 shrink-0 rounded-full bg-deep" />
        <span title={origin} className="min-w-0 truncate font-medium text-navy">
          {origin}
        </span>
      </span>
      <span className="flex min-w-0 items-center gap-2">
        <span
          aria-hidden="true"
          data-route-line=""
          className="relative -my-1 flex h-4 w-2 shrink-0 justify-center rtl:-scale-x-100"
        >
          <span className="absolute -top-2 h-4 border-s-[1.5px] border-dashed border-light" />
          <span className="relative mt-auto size-2.5 rounded-full border-2 border-signal bg-white" />
        </span>
        <span title={destination} className="min-w-0 truncate text-navy">
          {destination}
        </span>
      </span>
      {when ? (
        <span className="ps-4 text-xs text-ink-muted tabular">
          {formatDateTime(when, i18n.language)}
        </span>
      ) : null}
    </span>
  )
}
