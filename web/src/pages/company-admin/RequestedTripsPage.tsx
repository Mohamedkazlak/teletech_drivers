import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Branch, TripRequest, TripRequestStatus } from '../../api/types'
import { requestedTripsQuery } from '../../api/company-queries'
import {
  useGroupingSuggestions,
  useTripRequest,
  useTripRequests,
  useApproveTripRequest,
  useRejectTripRequest,
} from '../../api/use-trip-requests'
import { PageHeading } from '../../components/layout/AppShell'
import { BranchFilter, type BranchFilterValue } from '../../components/ui/BranchFilter'
import { BranchText } from '../../components/ui/BranchText'
import { ConfirmDialog } from '../../components/ui/ConfirmDialog'
import { FilterBar } from '../../components/ui/FilterBar'
import { RowActions } from '../../components/ui/RowActions'
import { RequestStatusCell } from '../../components/trips/RequestStatusCell'
import { RouteCell } from '../../components/trips/RouteCell'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { FilterSelect } from '../../components/ui/FilterSelect'
import { FormField } from '../../components/ui/FormField'
import { controlClass, ghostButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { fieldDescribedBy } from '../../components/ui/described-by'
import { firstFieldError, messageForApiError } from '../../lib/api-message'
import { formatWhen } from '../../lib/format'
import { isBranch, localizedName } from '../../lib/names'
import { useListParams } from '../../lib/use-list-params'
import { GroupingPanel } from './GroupingPanel'
import { RequestDetailDialog } from './RequestDetailDialog'

const STATUSES: TripRequestStatus[] = ['pending', 'approved', 'rejected']

function readStatus(value: string | null): TripRequestStatus {
  if (value === 'approved' || value === 'rejected' || value === 'pending') return value
  return 'pending'
}

function readBranch(value: string | null): BranchFilterValue {
  return isBranch(value) ? value : ''
}

const FILTER_KEYS = ['status', 'branch'] as const

export function RequestedTripsPage() {
  const { t, i18n } = useTranslation()
  const toast = useToast()
  const { params, set, page, setPage, countActive, clear } = useListParams()
  const status = readStatus(params.get('status'))
  const highlight = params.get('request')
  const branch = readBranch(params.get('branch'))
  const query = useMemo(() => requestedTripsQuery({ status, branch, page }), [status, branch, page])
  const list = useTripRequests(query)
  const suggestions = useGroupingSuggestions(status === 'pending')
  const approve = useApproveTripRequest()
  const reject = useRejectTripRequest()
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const detail = useTripRequest(selectedId)
  const [approveId, setApproveId] = useState<string | null>(null)
  const [rejectId, setRejectId] = useState<string | null>(null)
  const [reason, setReason] = useState('')
  const [reasonError, setReasonError] = useState<string | null>(null)

  useEffect(() => {
    if (!highlight) return
    document.getElementById(`request-${highlight}`)?.scrollIntoView({ block: 'center' })
  }, [highlight, list.data])

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
        accessor: (row) => <RouteCell from={row.pickup.name} to={row.destination.name} />,
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
        accessor: (row) => <RequestStatusCell status={row.status} tripId={row.trip_id} />,
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
          <RowActions
            label={t('table.actionsFor', {
              name: localizedName(i18n.language, row.employee_name_en, row.employee_name_ar),
            })}
            primary={
              <button
                type="button"
                className={ghostButtonClass}
                onClick={() => setSelectedId(row.id)}
              >
                {t('common.view')}
              </button>
            }
            items={
              row.status === 'pending'
                ? [
                    { label: t('requests.approve'), onSelect: () => setApproveId(row.id) },
                    {
                      label: t('requests.reject'),
                      danger: true,
                      onSelect: () => {
                        setReason('')
                        setReasonError(null)
                        setRejectId(row.id)
                      },
                    },
                  ]
                : []
            }
          />
        ),
      },
    ],
    [i18n.language, t],
  )

  function openReject(id: string) {
    setReason('')
    setReasonError(null)
    setRejectId(id)
  }

  async function confirmApprove() {
    if (!approveId) return
    try {
      await approve.mutateAsync(approveId)
      toast(t('requests.approvedToast'), 'success')
      setApproveId(null)
    } catch (error) {
      toast(messageForApiError(error, t), 'error')
    }
  }

  async function confirmReject() {
    if (!rejectId) return
    const rejectionReason = reason.trim()
    try {
      await reject.mutateAsync({ id: rejectId, body: { rejection_reason: rejectionReason } })
      toast(t('requests.rejectedToast'), 'success')
      setRejectId(null)
    } catch (error) {
      const field = firstFieldError(error, 'rejection_reason')
      if (field) {
        setReasonError(field)
        return
      }
      toast(messageForApiError(error, t), 'error')
    }
  }

  const rows = list.data?.data ?? []
  const suggestionRows = (suggestions.data?.data ?? []).filter(
    (item) => item.request_ids.length >= 2,
  )

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.requestedTrips')} />
      <FilterBar activeCount={countActive(FILTER_KEYS)} onClear={() => clear(FILTER_KEYS)}>
        <FilterSelect
          label={t('requests.approval')}
          value={status}
          onChange={(next) => set({ status: next })}
          options={STATUSES.map((item) => ({ value: item, label: t(`status.${item}`) }))}
        />
        <BranchFilter
          value={branch}
          onChange={(next: Branch | '') => set({ branch: next || null })}
        />
      </FilterBar>
      {status === 'pending' && suggestions.isError ? (
        <p role="alert" className="text-sm text-danger">
          {messageForApiError(suggestions.error, t)}
        </p>
      ) : null}
      {status === 'pending' ? <GroupingPanel suggestions={suggestionRows} /> : null}
      <DataTable
        columns={columns}
        rows={rows}
        rowKey={(row) => row.id}
        rowDomId={(row) => `request-${row.id}`}
        rowClassName={(row) =>
          row.id === highlight ? 'bg-pale outline outline-2 outline-deep' : undefined
        }
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
        onRowClick={(row) => setSelectedId(row.id)}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <RequestDetailDialog
        request={selectedId ? (detail.data ?? null) : null}
        isLoading={selectedId !== null && detail.isPending}
        error={selectedId && detail.isError ? messageForApiError(detail.error, t) : null}
        onClose={() => setSelectedId(null)}
        onApprove={setApproveId}
        onReject={openReject}
      />
      <ConfirmDialog
        open={approveId !== null}
        title={t('requests.approveTitle')}
        description={t('requests.approveMessage')}
        confirmLabel={t('requests.confirmApprove')}
        cancelLabel={t('common.cancel')}
        busy={approve.isPending}
        onCancel={() => setApproveId(null)}
        onConfirm={() => {
          void confirmApprove()
        }}
      />
      <ConfirmDialog
        open={rejectId !== null}
        title={t('requests.rejectTitle')}
        description={t('requests.rejectMessage')}
        confirmLabel={t('requests.confirmReject')}
        cancelLabel={t('common.cancel')}
        tone="danger"
        busy={reject.isPending}
        confirmDisabled={reason.trim() === '' || reason.trim().length > 500}
        onCancel={() => setRejectId(null)}
        onConfirm={() => {
          void confirmReject()
        }}
      >
        <FormField
          id="rejection-reason"
          label={t('requests.reason')}
          error={reasonError ?? undefined}
        >
          <textarea
            id="rejection-reason"
            className={`${controlClass} h-24 py-2`}
            maxLength={500}
            autoFocus
            value={reason}
            aria-describedby={fieldDescribedBy('rejection-reason', reasonError ?? undefined)}
            onChange={(event) => {
              setReason(event.target.value)
              setReasonError(null)
            }}
          />
        </FormField>
      </ConfirmDialog>
    </section>
  )
}
