import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { driversListQuery } from '../../api/drivers'
import type { Driver } from '../../api/types'
import { useDrivers } from '../../api/use-drivers'
import { PageHeading } from '../../components/layout/AppShell'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { FormField } from '../../components/ui/FormField'
import { controlClass, secondaryButtonClass } from '../../components/ui/styles'
import { messageForApiError } from '../../lib/api-message'
import { localizedName } from '../../lib/names'
import { ExportReportDialog } from '../drivers-admin/ExportReportDialog'

export function DriverReportsPage() {
  const { t, i18n } = useTranslation()
  const [search, setSearch] = useState('')
  const [applied, setApplied] = useState('')
  const [page, setPage] = useState(1)
  const [exporting, setExporting] = useState<Driver | null>(null)
  const query = useMemo(
    () => driversListQuery({ attendance: '', search: applied, page }),
    [applied, page],
  )
  const list = useDrivers(query)

  useEffect(() => {
    const handle = window.setTimeout(() => {
      const next = search.trim()
      if (next === applied) return
      setApplied(next)
      setPage(1)
    }, 300)
    return () => window.clearTimeout(handle)
  }, [search, applied])

  const columns = useMemo<Column<Driver>[]>(
    () => [
      {
        id: 'name',
        header: t('places.name'),
        sortValue: (row) => localizedName(i18n.language, row.name_en, row.name_ar),
        accessor: (row) => localizedName(i18n.language, row.name_en, row.name_ar),
      },
      {
        id: 'export',
        header: t('driverAdmin.exportReport'),
        accessor: (row) => (
          <button
            type="button"
            className={secondaryButtonClass}
            onClick={() => setExporting(row)}
          >
            {t('driverAdmin.exportReport')}
          </button>
        ),
      },
    ],
    [i18n.language, t],
  )

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('driverAdmin.driverReports')} />
      <p className="text-sm text-ink-muted">{t('driverAdmin.driverReportsHint')}</p>
      <FormField id="driver-report-search" label={t('driverAdmin.search')}>
        <input
          id="driver-report-search"
          className={controlClass}
          type="search"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
      </FormField>
      <DataTable
        columns={columns}
        rows={list.data?.data ?? []}
        rowKey={(row) => row.id}
        isLoading={list.isPending}
        error={list.isError ? messageForApiError(list.error, t) : null}
        onRetry={() => void list.refetch()}
        emptyLabel={t('driverAdmin.empty')}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={setPage}
      />
      <ExportReportDialog
        open={exporting !== null}
        driverId={exporting?.id ?? ''}
        driverName={
          exporting ? localizedName(i18n.language, exporting.name_en, exporting.name_ar) : ''
        }
        onClose={() => setExporting(null)}
      />
    </section>
  )
}
