import { useMemo, useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'

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
    <div className="overflow-hidden rounded-card border border-pale bg-white">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[36rem] border-collapse text-start text-sm">
          <thead className="bg-pale text-navy/75">
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
                    className="px-3 py-2 text-start font-semibold"
                  >
                    {column.sortValue ? (
                      <button
                        type="button"
                        className="inline-flex items-center gap-1 text-navy"
                        aria-label={t('table.sort', { column: column.header })}
                        onClick={() => toggleSort(column)}
                      >
                        {column.header}
                        <span aria-hidden="true">
                          {active === 'asc' ? '↑' : active === 'desc' ? '↓' : '↕'}
                        </span>
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
              <tr>
                <td colSpan={columns.length} className="px-3 py-8 text-center text-navy/75">
                  <span role="status">{t('common.loading')}</span>
                </td>
              </tr>
            ) : error ? (
              <tr>
                <td colSpan={columns.length} className="px-3 py-8 text-center">
                  <p role="alert" className="text-danger">
                    {error}
                  </p>
                  {onRetry ? (
                    <button
                      type="button"
                      className="mt-3 text-sm font-bold text-deep"
                      onClick={onRetry}
                    >
                      {t('common.retry')}
                    </button>
                  ) : null}
                </td>
              </tr>
            ) : sortedRows.length === 0 ? (
              <tr>
                <td colSpan={columns.length} className="px-3 py-8 text-center text-navy/75">
                  {emptyLabel ?? t('common.empty')}
                </td>
              </tr>
            ) : (
              sortedRows.map((row) => (
                <tr
                  key={rowKey(row)}
                  id={rowDomId?.(row)}
                  className={`border-t border-pale ${rowClassName?.(row) ?? ''}`}
                >
                  {columns.map((column) => (
                    <td key={column.id} className="px-3 py-2 text-navy">
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
        <div className="flex items-center justify-between gap-3 border-t border-pale px-3 py-2">
          <button
            type="button"
            className="h-10 rounded-control border-[1.5px] border-deep px-3 text-sm font-bold text-deep disabled:opacity-40"
            disabled={page <= 1}
            onClick={() => onPageChange(page - 1)}
          >
            {t('common.previous')}
          </button>
          <p className="text-sm text-navy/75">
            {t('common.page', { current: page, last: lastPage })}
          </p>
          <button
            type="button"
            className="h-10 rounded-control border-[1.5px] border-deep px-3 text-sm font-bold text-deep disabled:opacity-40"
            disabled={page >= lastPage}
            onClick={() => onPageChange(page + 1)}
          >
            {t('common.next')}
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
