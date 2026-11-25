import { useMemo, useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import {
  AlertIcon,
  ChevronEndIcon,
  ChevronStartIcon,
  RefreshIcon,
  SortIcon,
} from '../icons'
import { ghostButtonClass } from './styles'

export type Column<T> = {
  id: string
  header: string
  accessor: (row: T) => ReactNode
  sortValue?: (row: T) => string | number | null
}

type DataTableProps<T> = {
  columns: Column<T>[]
  rows: T[]
  rowKey: (row: T) => string
  isLoading?: boolean
  error?: string | null
  onRetry?: () => void
  emptyLabel?: string
  page?: number
  lastPage?: number
  onPageChange?: (page: number) => void
  rowClassName?: (row: T) => string | undefined
  rowDomId?: (row: T) => string | undefined
}

type SortState = { id: string; direction: 'asc' | 'desc' }

export function DataTable<T>({
  columns,
  rows,
  rowKey,
  isLoading = false,
  error = null,
  onRetry,
  emptyLabel,
  page = 1,
  lastPage = 1,
  onPageChange,
  rowClassName,
  rowDomId,
}: DataTableProps<T>) {
  const { t } = useTranslation()
  const [sort, setSort] = useState<SortState | null>(null)

  const sortedRows = useMemo(() => {
    if (!sort) return rows
    const column = columns.find((item) => item.id === sort.id)
    const sortValue = column?.sortValue
    if (!sortValue) return rows
    const copy = [...rows]
    copy.sort((left, right) => {
      const result = compareValues(sortValue(left), sortValue(right))
      return sort.direction === 'asc' ? result : -result
    })
    return copy
  }, [columns, rows, sort])

  function toggleSort(column: Column<T>) {
    if (!column.sortValue) return
    setSort((current) => {
      if (current?.id !== column.id) return { id: column.id, direction: 'asc' }
      if (current.direction === 'asc') return { id: column.id, direction: 'desc' }
      return null
    })
  }

  return (
    <div className="overflow-hidden rounded-card border border-line bg-white">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[36rem] border-collapse text-start text-sm">
          <thead className="border-b border-line bg-scaffold/70 text-[12.5px] text-ink-muted">
            <tr>
              {columns.map((column) => {
                const active = sort?.id === column.id ? sort.direction : undefined
                return (
                  <th
                    key={column.id}
                    scope="col"
                    aria-sort={
                      active === 'asc' ? 'ascending' : active === 'desc' ? 'descending' : 'none'
                    }
                    className="h-11 px-4 text-start font-medium whitespace-nowrap"
                  >
                    {column.sortValue ? (
                      <button
                        type="button"
                        className={`-mx-1.5 inline-flex items-center gap-1 rounded-md px-1.5 py-1 transition-colors duration-150 hover:bg-pale hover:text-navy ${active ? 'text-navy' : ''}`}
                        aria-label={t('table.sort', { column: column.header })}
                        onClick={() => toggleSort(column)}
                      >
                        {column.header}
                        <SortIcon
                          size={15}
                          direction={active}
                          className={active ? 'text-deep' : 'text-ink-muted/60'}
                        />
                      </button>
                    ) : (
                      column.header
                    )}
                  </th>
                )
              })}
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <>
                <tr className="sr-only">
                  <td colSpan={columns.length}>
                    <span role="status">{t('common.loading')}</span>
                  </td>
                </tr>
                {[0, 1, 2, 3, 4].map((index) => (
                  <tr key={index} aria-hidden="true" className="border-t border-line first:border-t-0">
                    {columns.map((column, columnIndex) => (
                      <td key={column.id} className="h-14 px-4">
                        <span
                          className="skeleton block h-3.5"
                          style={{ width: `${columnIndex === 0 ? 70 : 40 + ((index * 17 + columnIndex * 23) % 45)}%` }}
                        />
                      </td>
                    ))}
                  </tr>
                ))}
              </>
            ) : error ? (
              <tr>
                <td colSpan={columns.length} className="px-4 py-12 text-center">
                  <div className="mx-auto flex max-w-sm flex-col items-center gap-3">
                    <span className="inline-flex h-11 w-11 items-center justify-center rounded-full bg-danger/10 text-danger-ink">
                      <AlertIcon size={22} />
                    </span>
                    <p role="alert" className="text-danger-ink">
                      {error}
                    </p>
                    {onRetry ? (
                      <button type="button" className={ghostButtonClass} onClick={onRetry}>
                        <RefreshIcon size={16} />
                        {t('common.retry')}
                      </button>
                    ) : null}
                  </div>
                </td>
              </tr>
            ) : sortedRows.length === 0 ? (
              <tr>
                <td colSpan={columns.length} className="px-4 py-14 text-center">
                  <div className="mx-auto flex max-w-sm flex-col items-center gap-3 text-ink-muted">
                    <EmptyRoute />
                    <p>{emptyLabel ?? t('common.empty')}</p>
                  </div>
                </td>
              </tr>
            ) : (
              sortedRows.map((row) => (
                <tr
                  key={rowKey(row)}
                  id={rowDomId?.(row)}
                  className={`border-t border-line transition-colors duration-150 first:border-t-0 hover:bg-scaffold/80 ${rowClassName?.(row) ?? ''}`}
                >
                  {columns.map((column) => (
                    <td key={column.id} className="px-4 py-3 align-middle text-navy">
                      {column.accessor(row)}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      {onPageChange ? (
        <div className="flex items-center justify-between gap-3 border-t border-line px-3 py-2.5">
          <button
            type="button"
            className={`${ghostButtonClass} disabled:opacity-40`}
            disabled={page <= 1}
            onClick={() => onPageChange(page - 1)}
          >
            <ChevronStartIcon size={16} />
            {t('common.previous')}
          </button>
          <p className="text-sm text-ink-muted tabular">
            {t('common.page', { current: page, last: lastPage })}
          </p>
          <button
            type="button"
            className={`${ghostButtonClass} disabled:opacity-40`}
            disabled={page >= lastPage}
            onClick={() => onPageChange(page + 1)}
          >
            {t('common.next')}
            <ChevronEndIcon size={16} />
          </button>
        </div>
      ) : null}
    </div>
  )
}

function compareValues(left: string | number | null, right: string | number | null): number {
  if (left === null && right === null) return 0
  if (left === null) return 1
  if (right === null) return -1
  if (typeof left === 'number' && typeof right === 'number') return left - right
  return String(left).localeCompare(String(right))
}

/** Small route drawing for empty tables (the app's empty-state motif). */
function EmptyRoute() {
  return (
    <svg width="72" height="52" viewBox="0 0 132 96" fill="none" aria-hidden="true">
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
