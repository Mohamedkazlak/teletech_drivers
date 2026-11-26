import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { employeesListQuery } from '../../api/employees'
import type { Branch, Employee } from '../../api/types'
import { useDeleteEmployee, useEmployees, useRestoreEmployee } from '../../api/use-employees'
import { PageHeading } from '../../components/layout/AppShell'
import { BranchFilter, type BranchFilterValue } from '../../components/ui/BranchFilter'
import { BranchText } from '../../components/ui/BranchText'
import { ConfirmDialog } from '../../components/ui/ConfirmDialog'
import { FilterBar } from '../../components/ui/FilterBar'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { FilterSelect } from '../../components/ui/FilterSelect'
import { IncludeDeletedToggle } from '../../components/ui/IncludeDeletedToggle'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { primaryButtonClass, secondaryButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { messageForApiError } from '../../lib/api-message'
import { isBranch, localizedName } from '../../lib/names'
import { useListParams } from '../../lib/use-list-params'
import { EmployeeFormDialog } from './EmployeeFormDialog'

type ActiveFilter = '' | 'true' | 'false'
type DialogMode = 'create' | 'edit' | 'view'

function readActive(value: string | null): ActiveFilter {
  if (value === 'true' || value === 'false') return value
  return ''
}

function readBranch(value: string | null): BranchFilterValue {
  return isBranch(value) ? value : ''
}

export function EmployeesPage() {
  const { t, i18n } = useTranslation()
  const toast = useToast()
  const { params, set, page, setPage } = useListParams()
  const searchParam = params.get('search') ?? ''
  const [search, setSearch] = useState(searchParam)
  const [syncedSearch, setSyncedSearch] = useState(searchParam)
  if (searchParam !== syncedSearch) {
    setSyncedSearch(searchParam)
    setSearch(searchParam)
  }
  const branch = readBranch(params.get('branch'))
  const active = readActive(params.get('active'))
  const includeDeleted = params.get('deleted') === '1'
  const query = useMemo(
    () => employeesListQuery({ search: searchParam, branch, active, includeDeleted, page }),
    [searchParam, branch, active, includeDeleted, page],
  )
  const list = useEmployees(query)
  const remove = useDeleteEmployee()
  const restore = useRestoreEmployee()
  const [mode, setMode] = useState<DialogMode | null>(null)
  const [selected, setSelected] = useState<Employee | null>(null)
  const [deleting, setDeleting] = useState<Employee | null>(null)
  const [restoring, setRestoring] = useState<Employee | null>(null)

  useEffect(() => {
    const handle = window.setTimeout(() => {
      if (search.trim() === searchParam.trim()) return
      set({ search: search.trim() || null })
    }, 300)
    return () => window.clearTimeout(handle)
  }, [search, searchParam, set])

  function open(next: DialogMode, employee: Employee | null) {
    setSelected(employee)
    setMode(next)
  }

  function closeDialog() {
    setMode(null)
    setSelected(null)
  }

  const columns = useMemo<Column<Employee>[]>(
    () => [
      {
        id: 'name',
        header: t('places.name'),
        sortValue: (row) => localizedName(i18n.language, row.name_en, row.name_ar),
        accessor: (row) => localizedName(i18n.language, row.name_en, row.name_ar),
      },
      {
        id: 'email',
        header: t('profile.email'),
        accessor: (row) => row.email,
      },
      {
        id: 'phone',
        header: t('profile.phone'),
        accessor: (row) => row.phone || t('common.dash'),
      },
      {
        id: 'branch',
        header: t('profile.branch'),
        accessor: (row) => <BranchText value={row.branch} />,
      },
      {
        id: 'active',
        header: t('employees.active'),
        accessor: (row) => (
          <span className="inline-flex flex-wrap gap-1">
            <StatusBadge status={row.is_active ? 'active' : 'inactive'} />
            {row.deleted_at ? <StatusBadge status="deleted" /> : null}
          </span>
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
              onClick={() => {
                setSelected(row)
                setMode('view')
              }}
            >
              {t('common.view')}
            </button>
            {row.deleted_at ? (
              <button
                type="button"
                className={secondaryButtonClass}
                onClick={() => setRestoring(row)}
              >
                {t('common.restore')}
              </button>
            ) : (
              <>
                <button
                  type="button"
                  className={secondaryButtonClass}
                  onClick={() => {
                    setSelected(row)
                    setMode('edit')
                  }}
                >
                  {t('common.edit')}
                </button>
                <button
                  type="button"
                  className={secondaryButtonClass}
                  onClick={() => setDeleting(row)}
                >
                  {t('common.delete')}
                </button>
              </>
            )}
          </div>
        ),
      },
    ],
    [i18n.language, t],
  )

  async function confirmDelete() {
    if (!deleting) return
    try {
      await remove.mutateAsync(deleting.id)
      toast(t('employees.deleted'), 'success')
      if (selected?.id === deleting.id) closeDialog()
      setDeleting(null)
    } catch (error) {
      toast(messageForApiError(error, t), 'error')
    }
  }

  async function confirmRestore() {
    if (!restoring) return
    try {
      await restore.mutateAsync(restoring.id)
      toast(t('employees.restored'), 'success')
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

  const activeFilters = [searchParam, branch, active, includeDeleted].filter(Boolean).length
  function clearFilters() {
    setSearch('')
    set({ search: null, branch: null, active: null, deleted: null })
  }

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.employees')}>
        <button type="button" className={primaryButtonClass} onClick={() => open('create', null)}>
          {t('employees.add')}
        </button>
      </PageHeading>
      <FilterBar
        search={{ value: search, onChange: setSearch, label: t('employees.search') }}
        activeCount={activeFilters}
        onClear={clearFilters}
      >
        <BranchFilter
          value={branch}
          onChange={(next: Branch | '') => set({ branch: next || null })}
        />
        <FilterSelect
          label={t('employees.active')}
          value={active}
          onChange={(next) => set({ active: next || null })}
          options={[
            { value: '', label: t('branch.all') },
            { value: 'true', label: t('status.active') },
            { value: 'false', label: t('status.inactive') },
          ]}
        />
        <IncludeDeletedToggle
          checked={includeDeleted}
          onChange={(checked) => set({ deleted: checked ? '1' : null })}
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
          message: t('employees.empty'),
          action: activeFilters ? { label: t('filters.clear'), onClick: clearFilters } : undefined,
        }}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <EmployeeFormDialog
        mode={mode}
        employee={mode === 'create' ? null : selected}
        onClose={closeDialog}
      />
      <ConfirmDialog
        open={deleting !== null}
        title={t('employees.deleteTitle')}
        description={t('employees.deleteMessage', { name: deletingName })}
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
        title={t('employees.restoreTitle')}
        description={t('employees.restoreMessage', { name: restoringName })}
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
