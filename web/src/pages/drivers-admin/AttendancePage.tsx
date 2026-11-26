import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import type { AttendancePeriod, AttendanceStatus } from '../../api/attendance'
import { useAdjustAttendance, useAttendanceList, useAttendanceSummary } from '../../api/use-attendance'
import { PageHeading } from '../../components/layout/AppShell'
import { DataTable, type Column } from '../../components/ui/DataTable'
import { DriverPicker } from '../../components/ui/DriverPicker'
import { FilterBar } from '../../components/ui/FilterBar'
import { FilterSelect } from '../../components/ui/FilterSelect'
import { PeriodControl } from '../../components/ui/PeriodControl'
import { FormField } from '../../components/ui/FormField'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { primaryButtonClass, secondaryButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { messageForApiError } from '../../lib/api-message'
import { localizedName } from '../../lib/names'
import { formatDate } from '../../lib/format'
import { formatDateParam } from '../../lib/period'
import { useListParams } from '../../lib/use-list-params'
import type { AttendanceDay } from '../../api/attendance'

type AttendanceView = 'day' | AttendancePeriod
const PERIODS: AttendanceView[] = ['day', 'week', 'month', 'year']
const FILTER_KEYS = ['period', 'date', 'status', 'driver'] as const
const statuses: Array<'' | AttendanceStatus> = ['', 'present', 'absent', 'checked_in', 'checked_out']

export function AttendancePage() {
  const { t, i18n } = useTranslation()
  const toast = useToast()
  const { params, set, page, countActive, clear } = useListParams()
  const date = params.get('date') || formatDateParam(new Date())
  const driverId = params.get('driver') ?? ''
  const period = readPeriod(params.get('period'))
  const status = readStatus(params.get('status'))
  const summary = useAttendanceSummary()
  // Day sends only the date, which the API reads as that single day.
  const list = useAttendanceList({
    date,
    driver_id: driverId || undefined,
    period: period === 'day' ? undefined : period,
    status: status || undefined,
    page,
  })
  const [adjusting, setAdjusting] = useState(false)

  const columns: Column<AttendanceDay>[] = [
    {
      id: 'driver',
      header: t('attendance.driver'),
      accessor: (row) => localizedName(i18n.language, row.driver_name_en, row.driver_name_ar),
    },
    {
      id: 'date',
      header: t('attendance.workDate'),
      accessor: (row) => formatDate(row.work_date, i18n.language),
    },
    {
      id: 'status',
      header: t('attendance.status'),
      accessor: (row) => <StatusBadge status={row.status} />,
    },
    {
      id: 'in',
      header: t('attendance.checkIn'),
      accessor: (row) => formatTime(row.checked_in_at),
    },
    {
      id: 'out',
      header: t('attendance.checkOut'),
      accessor: (row) => formatTime(row.checked_out_at) || t('attendance.noCheckOut'),
    },
    {
      id: 'hours',
      header: t('attendance.hours'),
      accessor: (row) => (row.on_site_hours == null ? t('common.dash') : String(row.on_site_hours)),
    },
  ]

  const counts = summary.data?.data.counts

  return (
    <section className="flex flex-col gap-4">
      <PageHeading title={t('nav.attendance')}>
        <div className="flex flex-wrap gap-2">
          <Link to="qr" className={secondaryButtonClass}>
            {t('attendance.qr')}
          </Link>
          <button type="button" className={primaryButtonClass} onClick={() => setAdjusting(true)}>
            {t('attendance.adjust')}
          </button>
        </div>
      </PageHeading>
      {counts ? (
        <div className="grid gap-3 sm:grid-cols-4">
          <Count label={t('attendance.present')} value={counts.present} />
          <Count label={t('attendance.checkedIn')} value={counts.checked_in} />
          <Count label={t('attendance.checkedOut')} value={counts.checked_out} />
          <Count label={t('attendance.absent')} value={counts.absent} />
        </div>
      ) : null}
      <FilterBar activeCount={countActive(FILTER_KEYS)} onClear={() => clear(FILTER_KEYS)}>
        <PeriodControl
          periods={PERIODS}
          value={{ period, date }}
          onChange={(next) =>
            set({ period: next.period === 'day' ? null : next.period, date: next.date ?? null })
          }
        />
        <FilterSelect
          label={t('attendance.status')}
          value={status}
          onChange={(next) => set({ status: next || null })}
          options={statuses.map((item) => ({
            value: item,
            label: item ? t(`attendance.${statusKey(item)}`) : t('branch.all'),
          }))}
        />
        <DriverPicker value={driverId || null} onChange={(next) => set({ driver: next })} />
      </FilterBar>
      {list.data?.totals ? (
        <p className="text-sm text-ink-muted">
          {t('attendance.totals', {
            present: list.data.totals.days_present,
            absent: list.data.totals.days_absent,
            hours: list.data.totals.total_on_site_hours,
          })}
        </p>
      ) : null}
      <DataTable
        columns={columns}
        rows={list.data?.data ?? []}
        rowKey={(row) => `${row.driver_id}-${row.work_date}`}
        isLoading={list.isPending}
        error={list.isError ? messageForApiError(list.error, t) : null}
        onRetry={() => void list.refetch()}
        page={list.data?.meta.current_page ?? page}
        lastPage={list.data?.meta.last_page ?? 1}
        onPageChange={(next) => set({ page: next > 1 ? String(next) : null }, false)}
      />
      {adjusting ? (
        <AdjustDialog
          driverId={driverId}
          onClose={() => setAdjusting(false)}
          onSaved={() => {
            toast(t('attendance.saved'), 'success')
            setAdjusting(false)
          }}
        />
      ) : null}
    </section>
  )
}

function Count({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-card border border-line bg-white px-4 py-3">
      <p className="text-sm text-ink-muted">{label}</p>
      <p className="text-2xl font-semibold text-navy">{value}</p>
    </div>
  )
}

function AdjustDialog({
  driverId,
  onClose,
  onSaved,
}: {
  driverId: string
  onClose: () => void
  onSaved: () => void
}) {
  const { t } = useTranslation()
  const adjust = useAdjustAttendance()
  const [form, setForm] = useState({
    driver_id: driverId,
    work_date: new Date().toISOString().slice(0, 10),
    check_in: '08:00',
    check_out: '',
    reason: '',
  })
  const [error, setError] = useState<string | null>(null)

  async function submit(event: FormEvent) {
    event.preventDefault()
    if (!form.reason.trim()) {
      setError(t('attendance.reasonRequired'))
      return
    }
    try {
      await adjust.mutateAsync({
        driver_id: form.driver_id,
        work_date: form.work_date,
        checked_in_at: cairoIso(form.work_date, form.check_in),
        checked_out_at: form.check_out ? cairoIso(form.work_date, form.check_out) : null,
        reason: form.reason.trim(),
      })
      onSaved()
    } catch (caught) {
      setError(messageForApiError(caught, t))
    }
  }

  return (
    <div className="fixed inset-0 z-40 overflow-y-auto bg-navy/40 p-4">
      <form
        className="mx-auto my-8 w-full max-w-md rounded-card bg-white p-5"
        onSubmit={(event) => void submit(event)}
      >
        <h2 className="text-lg font-semibold text-navy">{t('attendance.adjust')}</h2>
        <div className="mt-4 flex flex-col gap-3">
          <FormField id="adjust-driver" label={t('attendance.driver')}>
            <input
              id="adjust-driver"
              required
              className="w-full rounded-control border border-line px-3 py-2"
              value={form.driver_id}
              onChange={(event) => setForm({ ...form, driver_id: event.target.value })}
            />
          </FormField>
          <FormField id="adjust-date" label={t('attendance.workDate')}>
            <input
              id="adjust-date"
              required
              type="date"
              className="w-full rounded-control border border-line px-3 py-2"
              value={form.work_date}
              onChange={(event) => setForm({ ...form, work_date: event.target.value })}
            />
          </FormField>
          <FormField id="adjust-in" label={t('attendance.checkIn')}>
            <input
              id="adjust-in"
              required
              type="time"
              className="w-full rounded-control border border-line px-3 py-2"
              value={form.check_in}
              onChange={(event) => setForm({ ...form, check_in: event.target.value })}
            />
          </FormField>
          <FormField id="adjust-out" label={t('attendance.checkOut')}>
            <input
              id="adjust-out"
              type="time"
              className="w-full rounded-control border border-line px-3 py-2"
              value={form.check_out}
              onChange={(event) => setForm({ ...form, check_out: event.target.value })}
            />
          </FormField>
          <FormField id="adjust-reason" label={t('attendance.reason')}>
            <textarea
              id="adjust-reason"
              required
              className="w-full rounded-control border border-line px-3 py-2"
              value={form.reason}
              onChange={(event) => setForm({ ...form, reason: event.target.value })}
            />
          </FormField>
          {error ? <p className="text-sm text-danger">{error}</p> : null}
        </div>
        <div className="mt-4 flex justify-end gap-2">
          <button type="button" className={secondaryButtonClass} onClick={onClose}>
            {t('common.cancel')}
          </button>
          <button type="submit" className={primaryButtonClass} disabled={adjust.isPending}>
            {t('common.save')}
          </button>
        </div>
      </form>
    </div>
  )
}

function readPeriod(value: string | null): AttendanceView {
  if (value === 'week' || value === 'month' || value === 'year') return value
  return 'day'
}

function readStatus(value: string | null): '' | AttendanceStatus {
  if (value === 'present' || value === 'absent' || value === 'checked_in' || value === 'checked_out') {
    return value
  }
  return ''
}

function statusKey(status: AttendanceStatus): string {
  if (status === 'checked_in') return 'checkedIn'
  if (status === 'checked_out') return 'checkedOut'
  return status
}

function formatTime(value: string | null): string {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

function cairoIso(date: string, time: string): string {
  return `${date}T${time}:00+02:00`
}
