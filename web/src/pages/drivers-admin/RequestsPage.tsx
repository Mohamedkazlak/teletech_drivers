import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Branch, TripRequest } from '../../api/types'
import { driversRequestsQuery, type DriversRequestTab } from '../../api/drivers-queries'
import { useCreateTrips } from '../../api/use-trips'
import {
  useGroupingSuggestions,
  useTripRequest,
  useTripRequests,
} from '../../api/use-trip-requests'
import { PageHeading } from '../../components/layout/AppShell'
import { BranchFilter, type BranchFilterValue } from '../../components/ui/BranchFilter'
import { BranchText } from '../../components/ui/BranchText'
import { ConfirmDialog } from '../../components/ui/ConfirmDialog'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { fieldDescribedBy } from '../../components/ui/described-by'
import { FilterRow, FilterSelect } from '../../components/ui/FilterSelect'
import { FormField } from '../../components/ui/FormField'
import { controlClass, primaryButtonClass, secondaryButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { firstFieldError, messageForApiError } from '../../lib/api-message'
import {
  cairoInputToIso,
  isFutureCairoInput,
  isoToCairoInput,
  nextSlotInput,
} from '../../lib/cairo-schedule'
import { formatWhen } from '../../lib/format'
import { isBranch, localizedName } from '../../lib/names'
import { useListParams } from '../../lib/use-list-params'
import { GroupingPanel } from '../company-admin/GroupingPanel'
import { RequestDetailDialog } from '../company-admin/RequestDetailDialog'
import { AssignmentDialog } from './AssignmentDialog'

const TABS: DriversRequestTab[] = ['pending', 'approved']

function readTab(value: string | null): DriversRequestTab {
  return value === 'approved' ? 'approved' : 'pending'
}

function readBranch(value: string | null): BranchFilterValue {
  return isBranch(value) ? value : ''
}

export function RequestsPage() {
  const { t, i18n } = useTranslation()
  const toast = useToast()
  const { params, set, page, setPage } = useListParams()
  const tab = readTab(params.get('tab'))
  const highlight = params.get('request')
  const branch = readBranch(params.get('branch'))
  const query = useMemo(() => driversRequestsQuery({ tab, branch, page }), [tab, branch, page])
  const list = useTripRequests(query)

  useEffect(() => {
    if (!highlight) return
    document.getElementById(`request-${highlight}`)?.scrollIntoView({ block: 'center' })
  }, [highlight, list.data])
  const suggestions = useGroupingSuggestions(tab === 'pending')
  const createTrips = useCreateTrips()
  const [selected, setSelected] = useState<string[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const detail = useTripRequest(selectedId)
  const [assignTripId, setAssignTripId] = useState<string | null>(null)
  const [scheduleIds, setScheduleIds] = useState<string[] | null>(null)
  const [scheduleAt, setScheduleAt] = useState('')
  const [scheduleFieldError, setScheduleFieldError] = useState<string | null>(null)
  const [scheduleBanner, setScheduleBanner] = useState<string | null>(null)
  const [createError, setCreateError] = useState<string | null>(null)

  const rows = useMemo(() => {
    const data = [...(list.data?.data ?? [])]
    data.sort((left, right) => {
      const group = (left.suggested_group_id ?? '').localeCompare(right.suggested_group_id ?? '')
      if (group !== 0) return group
      return left.requested_at.localeCompare(right.requested_at)
    })
    return data
  }, [list.data])
  const selectedIds = selected.filter((id) => rows.some((row) => row.id === id))

  function toggle(id: string) {
    setSelected((current) =>
      current.includes(id) ? current.filter((item) => item !== id) : [...current, id],
    )
  }

  function openCreate(ids: string[], earliest?: string) {
    if (ids.length === 0) return
    setCreateError(null)
    if (ids.length > 1) {
      const fromRows = rows
        .filter((row) => ids.includes(row.id))
        .map((row) => row.requested_at)
        .sort()
      const iso = fromRows[0] ?? earliest ?? ''
      const cairo = iso ? isoToCairoInput(iso) : ''
      setScheduleAt(cairo && isFutureCairoInput(cairo) ? cairo : nextSlotInput())
      setScheduleFieldError(null)
      setScheduleBanner(null)
      setScheduleIds(ids)
      return
    }
    void createAndAssign(ids)
  }

  async function createAndAssign(ids: string[], scheduledAt?: string) {
    setCreateError(null)
    setScheduleBanner(null)
    setScheduleFieldError(null)
    if (ids.length > 1 && !scheduledAt) {
      setScheduleFieldError(t('validation.required'))
      return
    }
    if (ids.length > 1 && scheduledAt && !isFutureCairoInput(scheduledAt)) {
      setScheduleFieldError(t('myTrips.future'))
      return
    }
    try {
      const result = await createTrips.mutateAsync({
        mode: ids.length > 1 ? 'grouped' : 'one_per_request',
        request_ids: ids,
        ...(ids.length > 1 && scheduledAt
          ? { scheduled_at: cairoInputToIso(scheduledAt) }
          : {}),
      })
      const trip = result.data[0]
      if (!trip) {
        setCreateError(t('common.error'))
        return
      }
      setSelected([])
      setScheduleIds(null)
      toast(t('requests.tripCreated'), 'success')
      setAssignTripId(trip.id)
    } catch (error) {
      const field = firstFieldError(error, 'scheduled_at')
      if (ids.length > 1) {
        setScheduleFieldError(field ?? null)
        setScheduleBanner(field ? null : messageForApiError(error, t))
        return
      }
      setCreateError(messageForApiError(error, t))
    }
  }

  const columns: Column<TripRequest>[] = []
  if (tab === 'pending') {
    columns.push({
      id: 'select',
      header: t('requests.selection'),
      accessor: (row) => {
        const name =
          localizedName(i18n.language, row.employee_name_en, row.employee_name_ar) || row.id
        return (
          <input
            type="checkbox"
            checked={selected.includes(row.id)}
            aria-label={t('requests.select', { name })}
            onChange={() => toggle(row.id)}
          />
        )
      },
    })
  }
  columns.push(
    {
      id: 'requester',
      header: t('requests.requester'),
      sortValue: (row) => localizedName(i18n.language, row.employee_name_en, row.employee_name_ar),
      accessor: (row) => (
        <span className="inline-flex flex-wrap items-center gap-2">
          <span>
            {localizedName(i18n.language, row.employee_name_en, row.employee_name_ar) ||
              t('common.dash')}
          </span>
          {row.suggested_group_id ? (
            <span className="inline-flex rounded-chip bg-mid/20 px-2 py-0.5 text-xs font-semibold text-navy">
              {t('requests.groupBadge')}
            </span>
          ) : null}
        </span>
      ),
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
      id: 'notes',
      header: t('requests.notes'),
      accessor: (row) => (
        <span className="line-clamp-2 max-w-xs">{row.notes || t('common.dash')}</span>
      ),
    },
    {
      id: 'actions',
      header: t('common.actions'),
      accessor: (row) => (
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            className={secondaryButtonClass}
            onClick={() => setSelectedId(row.id)}
          >
            {t('common.view')}
          </button>
          {tab === 'pending' && !row.trip_id ? (
            <button
              type="button"
              className={secondaryButtonClass}
              disabled={createTrips.isPending}
              onClick={() => openCreate([row.id], row.requested_at)}
            >
              {t('requests.createTrip')}
            </button>
          ) : null}
        </div>
      ),
    },
  )

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.requests')} />
      <FilterRow>
        <FilterSelect
          label={t('requests.status')}
          value={tab}
          onChange={(next) => {
            setSelected([])
            set({ tab: next === 'pending' ? null : next })
          }}
          options={TABS.map((item) => ({ value: item, label: t(`status.${item}`) }))}
        />
        <BranchFilter
          value={branch}
          onChange={(next: Branch | '') => set({ branch: next || null })}
        />
      </FilterRow>
      {createError ? (
        <p role="alert" className="text-sm text-danger">
          {createError}
        </p>
      ) : null}
      {tab === 'pending' && suggestions.isError ? (
        <p role="alert" className="text-sm text-danger">
          {messageForApiError(suggestions.error, t)}
        </p>
      ) : null}
      {tab === 'pending' ? (
        <GroupingPanel
          suggestions={(suggestions.data?.data ?? []).filter(
            (item) => item.request_ids.length >= 2,
          )}
          hint={t('requests.groupsHintDrivers')}
          actions={(suggestion, memberIds) => (
            <button
              type="button"
              className={primaryButtonClass}
              disabled={memberIds.length < 1 || createTrips.isPending}
              onClick={() => openCreate(memberIds, suggestion.earliest_requested_at)}
            >
              {t('requests.createTrip')}
            </button>
          )}
        />
      ) : null}
      {tab === 'pending' && selectedIds.length > 0 ? (
        <div
          role="region"
          aria-label={t('requests.selection')}
          className="flex flex-wrap items-center justify-between gap-3 rounded-card border border-line bg-white px-4 py-3"
        >
          <p className="text-sm text-ink-muted">
            {t('requests.selectedCount', { count: selectedIds.length })}
          </p>
          <button
            type="button"
            className={primaryButtonClass}
            disabled={createTrips.isPending}
            onClick={() => openCreate(selectedIds)}
          >
            {t('requests.createTrip')}
          </button>
        </div>
      ) : null}
      <DataTable
        columns={columns}
        rows={rows}
        rowKey={(row) => row.id}
        rowDomId={(row) => `request-${row.id}`}
        rowClassName={(row) => (row.id === highlight ? 'bg-pale outline outline-2 outline-deep' : undefined)}
        isLoading={list.isPending}
        error={list.isError ? messageForApiError(list.error, t) : null}
        onRetry={() => {
          void list.refetch()
        }}
        emptyLabel={t('requests.empty')}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <RequestDetailDialog
        request={selectedId ? (detail.data ?? null) : null}
        isLoading={selectedId !== null && detail.isPending}
        error={selectedId && detail.isError ? messageForApiError(detail.error, t) : null}
        onClose={() => setSelectedId(null)}
      />
      <ConfirmDialog
        open={scheduleIds !== null}
        title={t('requests.scheduleTitle')}
        description={t('requests.scheduleMessage')}
        confirmLabel={t('requests.createTrip')}
        cancelLabel={t('common.cancel')}
        busy={createTrips.isPending}
        confirmDisabled={scheduleAt.trim() === ''}
        onCancel={() => setScheduleIds(null)}
        onConfirm={() => {
          if (!scheduleIds) return
          void createAndAssign(scheduleIds, scheduleAt)
        }}
      >
        {scheduleBanner ? (
          <p role="alert" className="mb-3 text-sm text-danger">
            {scheduleBanner}
          </p>
        ) : null}
        <FormField
          id="trip-schedule"
          label={t('requests.when')}
          error={scheduleFieldError ?? undefined}
        >
          <input
            id="trip-schedule"
            type="datetime-local"
            className={controlClass}
            min={nextSlotInput()}
            value={scheduleAt}
            aria-describedby={fieldDescribedBy('trip-schedule', scheduleFieldError ?? undefined)}
            onChange={(event) => {
              setScheduleAt(event.target.value)
              setScheduleFieldError(null)
            }}
          />
        </FormField>
      </ConfirmDialog>
      <AssignmentDialog
        key={assignTripId ?? 'assign-closed'}
        tripId={assignTripId}
        onClose={() => setAssignTripId(null)}
      />
    </section>
  )
}
