import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Place } from '../../api/types'
import { placesListQuery } from '../../api/company-queries'
import { useDeletePlace, usePlaces } from '../../api/use-places'
import { PageHeading } from '../../components/layout/AppShell'
import { ConfirmDialog } from '../../components/ui/ConfirmDialog'
import { FilterBar } from '../../components/ui/FilterBar'
import { RowActions } from '../../components/ui/RowActions'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { primaryButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { messageForApiError } from '../../lib/api-message'
import { localizedName } from '../../lib/names'
import { useListParams } from '../../lib/use-list-params'
import { PlaceDialogs } from './PlaceDialogs'

export function PlacesPage() {
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
  const query = useMemo(() => placesListQuery({ search: searchParam, page }), [searchParam, page])
  const list = usePlaces(query)
  const remove = useDeletePlace()
  const [viewing, setViewing] = useState<Place | null>(null)
  const [editing, setEditing] = useState<Place | null>(null)
  const [creating, setCreating] = useState(false)
  const [deleting, setDeleting] = useState<Place | null>(null)

  useEffect(() => {
    const handle = window.setTimeout(() => {
      if (search.trim() === searchParam.trim()) return
      set({ search: search.trim() || null })
    }, 300)
    return () => window.clearTimeout(handle)
  }, [search, searchParam, set])

  const columns = useMemo<Column<Place>[]>(
    () => [
      {
        id: 'name',
        header: t('places.name'),
        sortValue: (row) => localizedName(i18n.language, row.name_en, row.name_ar),
        mobile: 'title',
        accessor: (row) => (
          <button
            type="button"
            className="text-start font-medium text-deep underline-offset-2 hover:underline"
            onClick={() => setViewing(row)}
          >
            {localizedName(i18n.language, row.name_en, row.name_ar)}
          </button>
        ),
      },
      {
        id: 'address',
        header: t('places.address'),
        accessor: (row) => row.address || t('common.dash'),
      },
      {
        id: 'headquarters',
        header: t('places.headquarters'),
        accessor: (row) => (row.is_headquarters ? t('places.headquarters') : t('common.dash')),
      },
      {
        id: 'active',
        header: t('places.active'),
        accessor: (row) => <StatusBadge status={row.is_active ? 'active' : 'inactive'} />,
      },
      {
        id: 'actions',
        header: t('common.actions'),
        isActions: true,
        accessor: (row) => (
          <RowActions
            label={t('table.actionsFor', {
              name: localizedName(i18n.language, row.name_en, row.name_ar),
            })}
            items={[
              {
                label: t('common.edit'),
                onSelect: () => {
                  setViewing(null)
                  setEditing(row)
                },
              },
              { label: t('common.delete'), onSelect: () => setDeleting(row), danger: true },
            ]}
          />
        ),
      },
    ],
    [i18n.language, t],
  )

  async function confirmDelete() {
    if (!deleting) return
    try {
      await remove.mutateAsync(deleting.id)
      toast(t('places.deleted'), 'success')
      if (viewing?.id === deleting.id) setViewing(null)
      if (editing?.id === deleting.id) setEditing(null)
      setDeleting(null)
    } catch (error) {
      toast(messageForApiError(error, t), 'error')
    }
  }

  const activeFilters = searchParam ? 1 : 0
  function clearFilters() {
    setSearch('')
    set({ search: null })
  }

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.places')}>
        <button
          type="button"
          className={primaryButtonClass}
          onClick={() => {
            setViewing(null)
            setEditing(null)
            setCreating(true)
          }}
        >
          {t('places.add')}
        </button>
      </PageHeading>
      <FilterBar
        search={{ value: search, onChange: setSearch, label: t('places.search') }}
        activeCount={activeFilters}
        onClear={clearFilters}
      />
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
          message: t('places.empty'),
          action: activeFilters ? { label: t('filters.clear'), onClick: clearFilters } : undefined,
        }}
        total={list.data?.meta.total}
        onRowClick={setViewing}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <PlaceDialogs
        viewing={editing || creating ? null : viewing}
        editing={creating ? null : editing}
        creating={creating}
        onClose={() => {
          setViewing(null)
          setEditing(null)
          setCreating(false)
        }}
      />
      <ConfirmDialog
        open={deleting !== null}
        title={t('places.deleteTitle')}
        description={t('places.deleteMessage', {
          name: deleting ? localizedName(i18n.language, deleting.name_en, deleting.name_ar) : '',
        })}
        confirmLabel={t('common.delete')}
        cancelLabel={t('common.cancel')}
        tone="danger"
        busy={remove.isPending}
        onCancel={() => setDeleting(null)}
        onConfirm={() => {
          void confirmDelete()
        }}
      />
    </section>
  )
}
