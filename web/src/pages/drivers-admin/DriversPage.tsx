import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { driversListQuery } from '../../api/drivers'
import type { AttendanceListFilter } from '../../api/drivers'
import type { Driver } from '../../api/types'
import { useDeleteDriver, useDrivers, useRestoreDriver } from '../../api/use-drivers'
import { PageHeading } from '../../components/layout/AppShell'
import { ConfirmDialog } from '../../components/ui/ConfirmDialog'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { FilterBar } from '../../components/ui/FilterBar'
import { FilterSelect } from '../../components/ui/FilterSelect'
import { IncludeDeletedToggle } from '../../components/ui/IncludeDeletedToggle'
import { RowActions, type RowActionItem } from '../../components/ui/RowActions'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { primaryButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { messageForApiError } from '../../lib/api-message'
import { localizedName } from '../../lib/names'
import { useListParams } from '../../lib/use-list-params'
import { DriverFormDialog } from './DriverFormDialog'

type AttendanceFilter = '' | AttendanceListFilter

function readAttendance(value: string | null): AttendanceFilter {
  if (value === 'checked_in' || value === 'not_checked_in') return value
  return ''
}

type DriversPageProps = {
  /** Truthy include_deleted is admin-only. Other roles keep the toggle hidden. */
  allowDeleted?: boolean
}

export function DriversPage({ allowDeleted = false }: DriversPageProps) {
  const { t, i18n } = useTranslation()
  const toast = useToast()
  const navigate = useNavigate()
  const { params, set, page, setPage } = useListParams()
  const searchParam = params.get('search') ?? ''
  const [search, setSearch] = useState(searchParam)
  const [syncedSearch, setSyncedSearch] = useState(searchParam)
  if (searchParam !== syncedSearch) {
    setSyncedSearch(searchParam)
    setSearch(searchParam)
  }
  const attendance = readAttendance(params.get('attendance'))
  const includeDeleted = allowDeleted && params.get('deleted') === '1'
  const query = useMemo(
    () => driversListQuery({ attendance, search: searchParam, page, includeDeleted }),
    [attendance, searchParam, page, includeDeleted],
  )
  const list = useDrivers(query)
  const remove = useDeleteDriver()
  const restore = useRestoreDriver()
  const [creating, setCreating] = useState(false)
  const [editing, setEditing] = useState<Driver | null>(null)
  const [deleting, setDeleting] = useState<Driver | null>(null)
  const [restoring, setRestoring] = useState<Driver | null>(null)

  useEffect(() => {
    const handle = window.setTimeout(() => {
      if (search.trim() === searchParam.trim()) return
      set({ search: search.trim() || null })
    }, 300)
    return () => window.clearTimeout(handle)
  }, [search, searchParam, set])

  const columns = useMemo<Column<Driver>[]>(() => {
    return [
      {
        id: 'name',
        header: t('places.name'),
        sortValue: (row) => localizedName(i18n.language, row.name_en, row.name_ar),
        mobile: 'title',
        accessor: (row) => (
          <span className="flex flex-col items-start gap-1">
            <DriverName driver={row} language={i18n.language} />
            {row.deleted_at ? <StatusBadge status="deleted" /> : null}
          </span>
        ),
      },
      {
        id: 'phone',
        header: t('driverAdmin.phone'),
        accessor: (row) => row.phone || t('common.dash'),
      },
      {
        id: 'attendance',
        header: t('driverAdmin.filter'),
        accessor: (row) => (
          <StatusBadge status={row.is_available ? 'checked_in' : 'not_checked_in'} />
        ),
      },
      {
        id: 'car',
        header: t('driverAdmin.carLicense'),
        accessor: (row) => row.car_license || t('common.dash'),
      },
      {
        id: 'week',
        header: t('driverAdmin.tripsThisWeek'),
        sortValue: (row) => row.trips_this_week ?? null,
        accessor: (row) =>
          row.trips_this_week == null ? t('common.dash') : String(row.trips_this_week),
      },
      {
        id: 'actions',
        header: t('common.actions'),
        isActions: true,
        accessor: (row) => {
          const items: RowActionItem[] = row.deleted_at
            ? allowDeleted
              ? [{ label: t('common.restore'), onSelect: () => setRestoring(row) }]
              : []
            : [
                { label: t('common.edit'), onSelect: () => setEditing(row) },
                { label: t('common.delete'), onSelect: () => setDeleting(row), danger: true },
              ]
          if (items.length === 0) return null
          return (
            <RowActions
              label={t('table.actionsFor', {
                name: localizedName(i18n.language, row.name_en, row.name_ar),
              })}
              items={items}
            />
          )
        },
      },
    ]
  }, [allowDeleted, i18n.language, t])

  async function confirmDelete() {
    if (!deleting) return
    try {
      await remove.mutateAsync(deleting.id)
      toast(t('driverAdmin.deleted'), 'success')
      setDeleting(null)
      if (editing?.id === deleting.id) setEditing(null)
    } catch (error) {
      toast(messageForApiError(error, t), 'error')
    }
  }

  async function confirmRestore() {
    if (!restoring) return
    try {
      await restore.mutateAsync(restoring.id)
      toast(t('driverAdmin.restored'), 'success')
      setRestoring(null)
    } catch (error) {
      toast(messageForApiError(error, t), 'error')
    }
  }

  const deletingName = deleting
    ? localizedName(i18n.language, deleting.name_en, deleting.name_ar)
    : ''
  const restoringName = restoring
    ? localizedName(i18n.language, restoring.name_en, restoring.name_ar)
    : ''

  const activeFilters = [attendance, searchParam, includeDeleted].filter(Boolean).length
  function clearFilters() {
    setSearch('')
    set({ attendance: null, search: null, deleted: null })
  }

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.drivers')}>
        <button type="button" className={primaryButtonClass} onClick={() => setCreating(true)}>
          {t('driverAdmin.add')}
        </button>
      </PageHeading>
      <FilterBar
        search={{ value: search, onChange: setSearch, label: t('driverAdmin.search') }}
        activeCount={activeFilters}
        onClear={clearFilters}
      >
        <FilterSelect
          label={t('driverAdmin.filter')}
          value={attendance}
          onChange={(next) => set({ attendance: next || null })}
          options={[
            { value: '', label: t('branch.all') },
            { value: 'checked_in', label: t('attendance.checkedInToday') },
            { value: 'not_checked_in', label: t('attendance.notCheckedIn') },
          ]}
        />
        {allowDeleted ? (
          <IncludeDeletedToggle
            checked={includeDeleted}
            onChange={(checked) => set({ deleted: checked ? '1' : null })}
          />
        ) : null}
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
          message: t('driverAdmin.empty'),
          action: activeFilters ? { label: t('filters.clear'), onClick: clearFilters } : undefined,
        }}
        total={list.data?.meta.total}
        onRowClick={(row) => navigate(row.id)}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <DriverFormDialog
        mode={creating ? 'create' : editing ? 'edit' : null}
        driver={editing}
        onClose={() => {
          setCreating(false)
          setEditing(null)
        }}
      />
      <ConfirmDialog
        open={deleting !== null}
        title={t('driverAdmin.deleteTitle')}
        description={t('driverAdmin.deleteMessage', { name: deletingName })}
        confirmLabel={t('common.delete')}
        cancelLabel={t('common.cancel')}
        tone="danger"
        busy={remove.isPending}
        onCancel={() => setDeleting(null)}
        onConfirm={() => {
          void confirmDelete()
        }}
      />
      <ConfirmDialog
        open={restoring !== null}
        title={t('driverAdmin.restoreTitle')}
        description={t('driverAdmin.restoreMessage', { name: restoringName })}
        confirmLabel={t('common.restore')}
        cancelLabel={t('common.cancel')}
        busy={restore.isPending}
        onCancel={() => setRestoring(null)}
        onConfirm={() => {
          void confirmRestore()
        }}
      />
    </section>
  )
}

function DriverName({ driver, language }: { driver: Driver; language: string }) {
  const primary = localizedName(language, driver.name_en, driver.name_ar)
  const secondary = language.startsWith('ar') ? driver.name_en : driver.name_ar
  return (
    <span className="block">
      <Link to={driver.id} className="font-medium text-deep underline-offset-2 hover:underline">
        {primary}
      </Link>
      {secondary && secondary !== primary ? (
        <span className="mt-0.5 block text-xs text-ink-muted">{secondary}</span>
      ) : null}
    </span>
  )
}
