import { useMemo, useState, type MouseEvent, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { staggerDelay } from '../../lib/motion'
import { useMediaQuery } from '../../lib/use-media-query'
import { AlertIcon, ChevronEndIcon, ChevronStartIcon, RefreshIcon, SortIcon } from '../icons'
import { EmptyState, type EmptyStateAction } from './EmptyState'
import { ghostButtonClass } from './styles'

export type Column<T> = {
  id: string
  header: string
  accessor: (row: T) => ReactNode
  sortValue?: (row: T) => string | number | null
  /** Phone card role: the card heading, a label/value pair (default), or hidden. */
  mobile?: 'title' | 'meta' | 'hidden'
  /** The row's action cell (RowActions); sits top-end on phone cards. */
  isActions?: boolean
}

type DataTableProps<T> = {
  columns: Column<T>[]
  rows: T[]
  rowKey: (row: T) => string
  isLoading?: boolean
  error?: string | null
  onRetry?: () => void
  emptyLabel?: string
  /** Empty state with a reason and, when useful, a next step. Wins over emptyLabel. */
  empty?: { message: string; action?: EmptyStateAction }
  page?: number
  lastPage?: number
  onPageChange?: (page: number) => void
  /** Total matching rows across pages (the API's meta.total). */
  total?: number
  /** Makes the whole row open the item; clicks inside RowActions are ignored. */
  onRowClick?: (row: T) => void
  rowClassName?: (row: T) => string | undefined
  rowDomId?: (row: T) => string | undefined
}

type SortState = { id: string; direction: 'asc' | 'desc' }

const PHONE_QUERY = '(max-width: 639px)'

function fromRowActions(event: MouseEvent<HTMLElement>): boolean {
  const target = event.target as HTMLElement
  return Boolean(target.closest('[data-row-actions], a, button, input, select, label'))
}

export function DataTable<T>({
  columns,
  rows,
  rowKey,
  isLoading = false,
  error = null,
  onRetry,
  emptyLabel,
  empty,
  page = 1,
  lastPage = 1,
  onPageChange,
  total,
  onRowClick,
  rowClassName,
  rowDomId,
}: DataTableProps<T>) {
  const { t } = useTranslation()
  const phone = useMediaQuery(PHONE_QUERY)
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

  function rowClick(row: T) {
    if (!onRowClick) return undefined
    return (event: MouseEvent<HTMLElement>) => {
      if (fromRowActions(event)) return
      onRowClick(row)
    }
  }

  const status = isLoading ? (
    <>
      <span role="status" className="sr-only">
        {t('common.loading')}
      </span>
      <Skeleton columns={phone ? 2 : columns.length} />
    </>
  ) : error ? (
    <div className="mx-auto flex max-w-sm flex-col items-center gap-3 text-center">
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
  ) : sortedRows.length === 0 ? (
    <EmptyState
      message={empty?.message ?? emptyLabel ?? t('common.empty')}
      action={empty?.action}
    />
  ) : null

  const showPager = Boolean(onPageChange) && lastPage > 1
  const showCount = total !== undefined && !isLoading && !error && sortedRows.length > 0
  const footer =
    showPager || showCount ? (
      <div className="flex items-center justify-between gap-3 border-t border-line px-3 py-2.5">
        {showPager ? (
          <button
            type="button"
            className={`${ghostButtonClass} disabled:opacity-40`}
            disabled={page <= 1}
            onClick={() => onPageChange?.(page - 1)}
          >
            <ChevronStartIcon size={16} />
            {t('common.previous')}
          </button>
        ) : null}
        <p className="px-1 text-sm text-ink-muted tabular">
          {showPager
            ? t('common.page', { current: page, last: lastPage })
            : t('table.results', { count: total })}
        </p>
        {showPager ? (
          <button
            type="button"
            className={`${ghostButtonClass} disabled:opacity-40`}
            disabled={page >= lastPage}
            onClick={() => onPageChange?.(page + 1)}
          >
            {t('common.next')}
            <ChevronEndIcon size={16} />
          </button>
        ) : null}
      </div>
    ) : null

  if (phone) {
    const title = columns.find((column) => column.mobile === 'title') ?? columns[0]
    const actions = columns.find((column) => column.isActions)
    const meta = columns.filter(
      (column) => column !== title && column !== actions && column.mobile !== 'hidden',
    )
    return (
      <div className="overflow-hidden rounded-card border border-line bg-white">
        {status ? (
          <div className="px-4 py-12">{status}</div>
        ) : (
          <ul className="divide-y divide-line">
            {sortedRows.map((row, index) => (
              <li
                key={rowKey(row)}
                id={rowDomId?.(row)}
                onClick={rowClick(row)}
                style={{ animationDelay: `${staggerDelay(index)}ms` }}
                className={`flex flex-col gap-3 px-4 py-3.5 animate-row-in ${
                  onRowClick ? 'cursor-pointer active:bg-scaffold' : ''
                } ${rowClassName?.(row) ?? ''}`}
              >
                <div className="flex items-start justify-between gap-3">
                  <h3 className="min-w-0 pt-2 text-[15px] font-semibold text-navy">
                    {title.accessor(row)}
                  </h3>
                  {actions ? <div className="shrink-0">{actions.accessor(row)}</div> : null}
                </div>
                {meta.length > 0 ? (
                  <dl className="grid grid-cols-[auto_minmax(0,1fr)] gap-x-4 gap-y-1.5 text-sm">
                    {meta.map((column) => (
                      <div key={column.id} className="contents">
                        <dt className="text-ink-muted">{column.header}</dt>
                        <dd className="min-w-0 text-navy">{column.accessor(row)}</dd>
                      </div>
                    ))}
                  </dl>
                ) : null}
              </li>
            ))}
          </ul>
        )}
        {footer}
      </div>
    )
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
                    className={`h-11 px-4 font-medium whitespace-nowrap ${
                      column.isActions ? 'text-end' : 'text-start'
                    }`}
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
                    ) : column.isActions ? (
                      <span className="sr-only">{column.header}</span>
                    ) : (
                      column.header
                    )}
                  </th>
                )
              })}
            </tr>
          </thead>
          <tbody>
            {status ? (
              <tr>
                <td colSpan={columns.length} className={isLoading ? 'p-0' : 'px-4 py-14'}>
                  {status}
                </td>
              </tr>
            ) : (
              sortedRows.map((row, index) => (
                <tr
                  key={rowKey(row)}
                  id={rowDomId?.(row)}
                  onClick={rowClick(row)}
                  style={{ animationDelay: `${staggerDelay(index)}ms` }}
                  className={`border-t border-line transition-colors duration-150 first:border-t-0 hover:bg-scaffold/80 animate-row-in ${
                    onRowClick ? 'cursor-pointer' : ''
                  } ${rowClassName?.(row) ?? ''}`}
                >
                  {columns.map((column) => (
                    <td
                      key={column.id}
                      className={`px-4 py-3 align-middle text-navy ${column.isActions ? 'py-1.5 text-end' : ''}`}
                    >
                      {column.accessor(row)}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      {footer}
    </div>
  )
}

/** Five placeholder rows with deterministic widths (no layout jump when data lands). */
function Skeleton({ columns }: { columns: number }) {
  return (
    <div aria-hidden="true" className="divide-y divide-line">
      {[0, 1, 2, 3, 4].map((index) => (
        <div key={index} className="flex h-14 items-center gap-8 px-4">
          {Array.from({ length: columns }, (_, columnIndex) => (
            <span
              key={columnIndex}
              className="skeleton block h-3.5 flex-1"
              style={{
                maxWidth: `${columnIndex === 0 ? 70 : 40 + ((index * 17 + columnIndex * 23) % 45)}%`,
              }}
            />
          ))}
        </div>
      ))}
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
