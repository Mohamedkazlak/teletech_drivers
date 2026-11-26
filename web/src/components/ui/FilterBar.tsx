import { useId, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { CloseIcon, SearchIcon } from '../icons'
import { controlClass } from './styles'

type FilterBarProps = {
  /** Only on pages whose endpoint supports `search`. */
  search?: { value: string; onChange: (value: string) => void; label: string }
  /** Number of filters that differ from their defaults; shows "Clear filters" when > 0. */
  activeCount: number
  onClear: () => void
  children?: ReactNode
}

/*
  One filter row for every list page: search on the start side, then the
  page's compact controls, then "Clear filters" once anything is set.
*/
export function FilterBar({ search, activeCount, onClear, children }: FilterBarProps) {
  const { t } = useTranslation()
  const searchId = useId()

  return (
    <div className="mb-4 flex flex-wrap items-end gap-x-3 gap-y-2.5">
      {search ? (
        <div className="relative min-w-56 flex-1 sm:max-w-sm">
          <label htmlFor={searchId} className="sr-only">
            {search.label}
          </label>
          <SearchIcon
            size={18}
            className="pointer-events-none absolute start-3.5 top-1/2 -translate-y-1/2 text-ink-muted"
          />
          <input
            id={searchId}
            type="search"
            placeholder={search.label}
            className={`${controlClass} ps-10 pe-10 [&::-webkit-search-cancel-button]:hidden`}
            value={search.value}
            onChange={(event) => search.onChange(event.target.value)}
          />
          {search.value ? (
            <button
              type="button"
              aria-label={t('filters.clearSearch')}
              className="absolute end-1.5 top-1/2 inline-flex h-8 w-8 -translate-y-1/2 items-center justify-center rounded-[9px] text-ink-muted transition-colors duration-150 hover:bg-pale hover:text-navy animate-fade-quick"
              onClick={() => search.onChange('')}
            >
              <CloseIcon size={16} />
            </button>
          ) : null}
        </div>
      ) : null}
      {children}
      {activeCount > 0 ? (
        <button
          type="button"
          className="inline-flex h-[var(--control-height)] items-center rounded-control px-2 text-sm font-semibold text-deep underline-offset-4 transition-colors duration-150 hover:underline animate-fade-quick"
          onClick={onClear}
        >
          {t('filters.clear')}
        </button>
      ) : null}
    </div>
  )
}
