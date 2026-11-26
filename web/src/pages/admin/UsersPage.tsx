import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { usersListQuery, type Account } from '../../api/users'
import { useUsers } from '../../api/use-users'
import type { UserRole } from '../../api/types'
import { useAuth } from '../../auth/auth-context'
import { PageHeading } from '../../components/layout/AppShell'
import { FilterBar } from '../../components/ui/FilterBar'
import { RowActions } from '../../components/ui/RowActions'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { FilterSelect } from '../../components/ui/FilterSelect'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { messageForApiError } from '../../lib/api-message'
import { localizedName } from '../../lib/names'
import { useListParams } from '../../lib/use-list-params'
import { ResetPasswordDialog } from './ResetPasswordDialog'

const ROLES: UserRole[] = ['admin', 'company_admin', 'drivers_admin', 'driver', 'employee']

function readRole(value: string | null): UserRole | '' {
  return ROLES.includes(value as UserRole) ? (value as UserRole) : ''
}

export function UsersPage() {
  const { t, i18n } = useTranslation()
  const { user } = useAuth()
  const { params, set, page, setPage } = useListParams()
  const searchParam = params.get('search') ?? ''
  const [search, setSearch] = useState(searchParam)
  const [syncedSearch, setSyncedSearch] = useState(searchParam)
  if (searchParam !== syncedSearch) {
    setSyncedSearch(searchParam)
    setSearch(searchParam)
  }
  const role = readRole(params.get('role'))
  const query = useMemo(
    () => usersListQuery({ search: searchParam, role, page }),
    [searchParam, role, page],
  )
  const list = useUsers(query)
  const [resetting, setResetting] = useState<Account | null>(null)

  useEffect(() => {
    const handle = window.setTimeout(() => {
      if (search.trim() === searchParam.trim()) return
      set({ search: search.trim() || null })
    }, 300)
    return () => window.clearTimeout(handle)
  }, [search, searchParam, set])

  const columns = useMemo<Column<Account>[]>(
    () => [
      {
        id: 'name',
        header: t('places.name'),
        sortValue: (row) => localizedName(i18n.language, row.name_en, row.name_ar),
        mobile: 'title',
        accessor: (row) => (
          <span className="inline-flex flex-wrap items-center gap-2">
            {localizedName(i18n.language, row.name_en, row.name_ar)}
            {row.id === user?.id ? (
              <span className="rounded-chip bg-pale px-2 py-0.5 text-xs font-semibold text-deep">
                {t('users.you')}
              </span>
            ) : null}
          </span>
        ),
      },
      {
        id: 'email',
        header: t('profile.email'),
        accessor: (row) => row.email,
      },
      {
        id: 'role',
        header: t('users.role'),
        accessor: (row) => t(`role.${row.role}`),
      },
      {
        id: 'active',
        header: t('employees.active'),
        accessor: (row) => (
          <span className="inline-flex flex-wrap gap-1">
            <StatusBadge status={row.is_active ? 'active' : 'inactive'} />
            {row.must_change_password ? (
              <span className="rounded-full bg-warning/14 px-2 py-0.5 text-xs font-semibold text-warning">
                {t('users.temporary')}
              </span>
            ) : null}
          </span>
        ),
      },
      {
        id: 'actions',
        header: t('common.actions'),
        isActions: true,
        accessor: (row) =>
          row.id === user?.id ? null : (
            <RowActions
              label={t('table.actionsFor', {
                name: localizedName(i18n.language, row.name_en, row.name_ar),
              })}
              items={[{ label: t('users.reset'), onSelect: () => setResetting(row) }]}
            />
          ),
      },
    ],
    [i18n.language, t, user?.id],
  )

  const activeFilters = [searchParam, role].filter(Boolean).length
  function clearFilters() {
    setSearch('')
    set({ search: null, role: null })
  }

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.users')} />
      <FilterBar
        search={{ value: search, onChange: setSearch, label: t('users.search') }}
        activeCount={activeFilters}
        onClear={clearFilters}
      >
        <FilterSelect
          label={t('users.role')}
          value={role}
          onChange={(next) => set({ role: next || null })}
          options={[
            { value: '', label: t('users.allRoles') },
            ...ROLES.map((item) => ({ value: item, label: t(`role.${item}`) })),
          ]}
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
          message: t('users.empty'),
          action: activeFilters ? { label: t('filters.clear'), onClick: clearFilters } : undefined,
        }}
        total={list.data?.meta.total}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <ResetPasswordDialog account={resetting} onClose={() => setResetting(null)} />
    </section>
  )
}
