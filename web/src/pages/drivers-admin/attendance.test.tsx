import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import { formatDateParam } from '../../lib/period'
import { driver, paginated, renderPage } from '../../test/render-page'
import { AttendancePage } from './AttendancePage'
import { AttendanceQrPage } from './AttendanceQrPage'

vi.mock('../../api/client', () => ({
  api: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), delete: vi.fn() },
}))

const http = vi.mocked(api)

function attendanceQueries(): Array<Record<string, unknown> | undefined> {
  return http.get.mock.calls
    .filter(([path]) => path === '/attendance')
    .map(([, options]) => (options as { query?: Record<string, unknown> } | undefined)?.query)
}

describe('attendance page', () => {
  beforeEach(() => {
    http.get.mockReset()
    http.post.mockReset()
    http.get.mockImplementation(async (path: string) => {
      if (path === '/attendance/today/summary') {
        return {
          data: {
            work_date: '2026-11-22',
            off_day: false,
            counts: { present: 2, checked_in: 1, checked_out: 1, absent: 1 },
            present: [],
            checked_in: [],
            checked_out: [],
            absent: [],
          },
        }
      }
      if (path === '/attendance') {
        return {
          data: [
            {
              driver_id: 'driver-1',
              driver_name_en: 'Nader Ali',
              driver_name_ar: 'نادر',
              work_date: '2026-11-22',
              status: 'checked_in',
              checked_in_at: '2026-11-22T06:00:00.000Z',
              checked_out_at: null,
              on_site_hours: null,
              source: 'scan',
              adjustment_reason: null,
            },
          ],
          totals: { days_present: 1, days_absent: 0, total_on_site_hours: 0 },
          meta: { current_page: 1, per_page: 15, total: 1, last_page: 1 },
        }
      }
      if (path === '/drivers') {
        return paginated([
          driver(),
          driver({ id: 'driver-2', name_en: 'Huda Samir', name_ar: 'هدى سمير' }),
        ])
      }
      throw new Error(path)
    })
  })

  it('shows today counts and the attendance table', async () => {
    renderPage(<AttendancePage />)
    expect(await screen.findByText('Nader Ali')).toBeInTheDocument()
    expect(screen.getByText('No check-out')).toBeInTheDocument()
    expect(screen.getByText('Present 1, absent 0, on-site 0 h')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Attendance QR' })).toHaveAttribute('href', '/qr')
  })

  it('opens on today and switches to a week range', async () => {
    const user = userEvent.setup()
    renderPage(<AttendancePage />)
    await screen.findByText('Nader Ali')

    const today = formatDateParam(new Date())
    expect(attendanceQueries().at(-1)).toMatchObject({ date: today })
    expect(attendanceQueries().at(-1)?.period).toBeUndefined()
    expect(screen.getByRole('radio', { name: 'Day' })).toHaveAttribute('aria-checked', 'true')
    expect(screen.queryByLabelText('Work date')).not.toBeInTheDocument()

    await user.click(screen.getByRole('radio', { name: 'Week' }))
    await waitFor(() => {
      expect(attendanceQueries().at(-1)).toMatchObject({ period: 'week', date: today })
    })
  })

  it('filters by a driver picked by name', async () => {
    const user = userEvent.setup()
    renderPage(<AttendancePage />)
    await screen.findByText('Nader Ali')

    await user.type(screen.getByRole('combobox', { name: 'Driver' }), 'hud')
    await user.click(await screen.findByRole('option', { name: 'Huda Samir' }))

    await waitFor(() => {
      expect(attendanceQueries().at(-1)).toMatchObject({ driver_id: 'driver-2' })
    })
    expect(screen.getByRole('combobox', { name: 'Driver' })).toHaveValue('Huda Samir')
  })

  it('names an active driver filter even when the driver is not in the roster', async () => {
    renderPage(<AttendancePage />, '/?driver=driver-9')
    await screen.findByText('Nader Ali')
    await waitFor(() => {
      expect(screen.getByRole('combobox', { name: 'Driver' })).toHaveValue('Unknown driver')
    })
  })

  it('does not offer Clear filters for today', async () => {
    renderPage(<AttendancePage />, `/?date=${formatDateParam(new Date())}`)
    await screen.findByText('Nader Ali')
    expect(screen.queryByRole('button', { name: 'Clear filters' })).not.toBeInTheDocument()
  })

  it('shows check-in times in Cairo time', async () => {
    renderPage(<AttendancePage />)
    expect(await screen.findByText(/8:00/)).toBeInTheDocument()
  })

  it('opens the driver list on ArrowDown with the first driver highlighted', async () => {
    const user = userEvent.setup()
    renderPage(<AttendancePage />)
    await screen.findByText('Nader Ali')
    const input = screen.getByRole('combobox', { name: 'Driver' })
    expect(input).not.toHaveAttribute('aria-controls')
    input.focus()
    await user.keyboard('{Escape}{ArrowDown}')
    const first = within(await screen.findByRole('listbox')).getAllByRole('option')[0]
    expect(input).toHaveAttribute('aria-activedescendant', first.id)
  })

  it('requires a reason before adjusting attendance', async () => {
    const user = userEvent.setup()
    renderPage(<AttendancePage />)
    await screen.findByText('Nader Ali')
    await user.click(screen.getByRole('button', { name: 'Adjust attendance' }))
    const form = screen.getByRole('heading', { name: 'Adjust attendance' }).closest('form')
    if (!form) throw new Error('adjust form missing')
    const dialog = within(form)
    await user.type(dialog.getByLabelText('Driver'), 'driver-1')
    await user.type(dialog.getByLabelText('Reason'), '   ')
    await user.click(dialog.getByRole('button', { name: 'Save' }))
    expect(await screen.findByText('Enter a reason.')).toBeInTheDocument()
    expect(http.post).not.toHaveBeenCalled()
  })
})

describe('attendance QR page', () => {
  beforeEach(() => {
    http.get.mockReset()
    http.get.mockResolvedValue({
      payload: 'telecars-attendance:v1:abc',
      hq_name: 'Company Headquarters',
      version: 1,
    })
  })

  it('renders the headquarters name and print action', async () => {
    renderPage(<AttendanceQrPage />)
    expect(await screen.findByRole('heading', { name: 'Company Headquarters' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Print' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Download PNG' })).toBeInTheDocument()
    await waitFor(() => {
      expect(document.querySelector('canvas')).not.toBeNull()
    })
  })
})
