import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { adminTripRequestsQuery, type RequestPeriod } from '../../api/admin-queries'
import type { Branch, TripRequest, TripRequestStatus } from '../../api/types'
import { useTripRequests } from '../../api/use-trip-requests'
import { PageHeading } from '../../components/layout/AppShell'
import { BranchFilter, type BranchFilterValue } from '../../components/ui/BranchFilter'
import { BranchText } from '../../components/ui/BranchText'
import { FilterBar } from '../../components/ui/FilterBar'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { FilterSelect } from '../../components/ui/FilterSelect'
import { PeriodControl } from '../../components/ui/PeriodControl'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { ghostButtonClass } from '../../components/ui/styles'
import { messageForApiError } from '../../lib/api-message'
import { formatWhen } from '../../lib/format'
import { isBranch, localizedName } from '../../lib/names'
import { formatDateParam } from '../../lib/period'
import { useListParams } from '../../lib/use-list-params'
import { RequestDetailDialog } from '../company-admin/RequestDetailDialog'

const STATUSES: TripRequestStatus[] = ['pending', 'approved', 'rejected', 'cancelled']

function readStatus(value: string | null): TripRequestStatus {
  if (value === 'approved' || value === 'rejected' || value === 'cancelled') return value
  return 'pending'
}

function readBranch(value: string | null): BranchFilterValue {
  return isBranch(value) ? value : ''
}

function readPeriod(value: string | null): RequestPeriod {
  if (value === 'week' || value === 'month' || value === 'year') return value
  return 'all'
}

const FILTER_KEYS = ['status', 'branch', 'period', 'date'] as const

export function TripRequestsPage() {
  const { t, i18n } = useTranslation()
  const { params, set, page, setPage, countActive, clear } = useListParams()
  const status = readStatus(params.get('status'))
  const branch = readBranch(params.get('branch'))
  const period = readPeriod(params.get('period'))
  const date = params.get('date') || formatDateParam(new Date())
  const query = useMemo(
    () => adminTripRequestsQuery({ status, branch, period, date, page }),
    [status, branch, period, date, page],
  )
  const list = useTripRequests(query)
  const [selected, setSelected] = useState<TripRequest | null>(null)

  const columns = useMemo<Column<TripRequest>[]>(
    () => [
      {
        id: 'requester',
        header: t('requests.requester'),
        sortValue: (row) =>
          localizedName(i18n.language, row.employee_name_en, row.employee_name_ar),
        accessor: (row) =>
          localizedName(i18n.language, row.employee_name_en, row.employee_name_ar) ||
          t('common.dash'),
      },
      {
        id: 'branch',
        header: t('profile.branch'),
        accessor: (row) => <BranchText value={row.employee_branch} />,
      },
      {
        id: 'route',
        header: t('requests.route'),
        accessor: (row) =>
          t('requests.routeValue', { from: row.pickup.name, to: row.destination.name }),
      },
      {
        id: 'when',
        header: t('requests.when'),
        sortValue: (row) => row.requested_at,
        accessor: (row) => formatWhen(row.requested_at, i18n.language),
      },
      {
        id: 'status',
        header: t('requests.status'),
        accessor: (row) => <StatusBadge status={row.status} />,
      },
      {
        id: 'notes',
        header: t('requests.notes'),
        accessor: (row) => (
          <span className="line-clamp-2 max-w-xs">{row.notes || t('common.dash')}</span>
        ),
      },
      {
        id: 'actions',
        header: t('common.actions'),
        isActions: true,
        accessor: (row) => (
          <button type="button" className={ghostButtonClass} onClick={() => setSelected(row)}>
            {t('common.view')}
          </button>
        ),
      },
    ],
    [i18n.language, t],
  )

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.tripRequests')} />
      <FilterBar activeCount={countActive(FILTER_KEYS)} onClear={() => clear(FILTER_KEYS)}>
        <FilterSelect
          label={t('requests.status')}
          value={status}
          onChange={(next) => set({ status: next === 'pending' ? null : next })}
          options={STATUSES.map((item) => ({ value: item, label: t(`status.${item}`) }))}
        />
        <BranchFilter
          value={branch}
          onChange={(next: Branch | '') => set({ branch: next || null })}
        />
        <PeriodControl
          periods={['week', 'month', 'year', 'all']}
          value={{ period, date: period === 'all' ? undefined : date }}
          onChange={(next) =>
            set({ period: next.period === 'all' ? null : next.period, date: next.date ?? null })
          }
        />
      </FilterBar>
      <DataTable
        columns={columns}
        rows={list.data?.data ?? []}
        rowKey={(row) => row.id}
        isLoading={list.isPending}
        error={list.isError ? messageForApiError(list.error, t) : null}
        onRetry={() => {
          void list.refetch()
        }}
        empty={{
          message: t('requests.empty'),
          action:
            countActive(FILTER_KEYS) > 0
              ? { label: t('filters.clear'), onClick: () => clear(FILTER_KEYS) }
              : undefined,
        }}
        total={list.data?.meta.total}
        onRowClick={(row) => setSelected(row)}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <RequestDetailDialog
        request={selected}
        isLoading={false}
        error={null}
        onClose={() => setSelected(null)}
      />
    </section>
  )
}
