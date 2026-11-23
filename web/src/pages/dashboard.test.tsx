import { screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../api/client'
import { ApiError } from '../api/errors'
import type { AdminDashboard } from '../api/types'
import i18n from '../i18n'
import { renderPage } from '../test/render-page'
import { DashboardPage } from './DashboardPage'

vi.mock('../components/charts/BarChartCard', () => ({
  BarChartCard: ({
    title,
    points,
  }: {
    title: string
    points: Array<{ label: string; value: number }>
  }) => (
    <section>
      <h2>{title}</h2>
      <ul>
        {points.map((point) => (
          <li key={point.label}>
            {point.label}: {point.value}
          </li>
        ))}
      </ul>
    </section>
  ),
}))

vi.mock('../api/client', () => ({
  api: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), delete: vi.fn() },
}))

const http = vi.mocked(api)

const summary: AdminDashboard = {
  drivers: { total: 10, checked_in: 4, checked_out: 3, absent: 3 },
  employees_total: 12,
  places_total: 3,
  trips: {
    unassigned: 2,
    assigned: 5,
    in_progress: 1,
    completed_today: 7,
    completed_this_week: 9,
  },
  requests: { pending: 8, approved: 11, rejected: 13 },
  unconfirmed_trips: 14,
}

describe('admin dashboard', () => {
  beforeEach(async () => {
    http.get.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockResolvedValue({ data: summary })
  })

  afterEach(async () => {
    await i18n.changeLanguage('en')
  })

  it('links each count to the matching list', async () => {
    renderPage(<DashboardPage />)

    expect(await screen.findByRole('link', { name: /Total drivers\s+10/ })).toHaveAttribute(
      'href',
      '/admin/drivers',
    )
    expect(screen.getByRole('link', { name: /Checked in\s+4/ })).toHaveAttribute(
      'href',
      '/admin/attendance',
    )
    expect(screen.getByRole('link', { name: /Checked out\s+3/ })).toHaveAttribute(
      'href',
      '/admin/attendance',
    )
    expect(screen.getByRole('link', { name: /Absent\s+3/ })).toHaveAttribute(
      'href',
      '/admin/attendance',
    )
    expect(screen.getByRole('link', { name: /Employees\s+12/ })).toHaveAttribute(
      'href',
      '/admin/employees',
    )
    expect(screen.getByRole('link', { name: /Places\s+3/ })).toHaveAttribute(
      'href',
      '/admin/places',
    )
    expect(screen.getByRole('link', { name: /Unassigned trips\s+2/ })).toHaveAttribute(
      'href',
      '/admin/trips?stage=unassigned',
    )
    expect(screen.getByRole('link', { name: /Assigned trips\s+5/ })).toHaveAttribute(
      'href',
      '/admin/trips?stage=assigned',
    )
    expect(screen.getByRole('link', { name: /Trips in progress\s+1/ })).toHaveAttribute(
      'href',
      '/admin/trips?stage=in_progress',
    )
    expect(screen.getByRole('link', { name: /Completed today\s+7/ })).toHaveAttribute(
      'href',
      '/admin/trips?stage=completed&finished_period=day',
    )
    expect(screen.getByRole('link', { name: /Completed this week\s+9/ })).toHaveAttribute(
      'href',
      '/admin/trips?stage=completed&finished_period=week',
    )
    expect(screen.getByRole('link', { name: /Pending requests\s+8/ })).toHaveAttribute(
      'href',
      '/admin/trip-requests?status=pending',
    )
    expect(screen.getByRole('link', { name: /Approved requests\s+11/ })).toHaveAttribute(
      'href',
      '/admin/trip-requests?status=approved',
    )
    expect(screen.getByRole('link', { name: /Rejected requests\s+13/ })).toHaveAttribute(
      'href',
      '/admin/trip-requests?status=rejected',
    )
    expect(screen.getByRole('link', { name: /Unconfirmed trips\s+14/ })).toHaveAttribute(
      'href',
      '/admin/trips?unconfirmed=true',
    )
    expect(screen.getByRole('heading', { name: 'Trips by status' })).toBeInTheDocument()
    expect(screen.getByText('Unassigned: 2')).toBeInTheDocument()
    expect(screen.getByText('Completed today: 7')).toBeInTheDocument()
    expect(http.get).toHaveBeenCalledWith('/admin/dashboard', expect.any(Object))
  })

  it('shows a loading state and a clear not-found error', async () => {
    http.get.mockImplementation(() => new Promise(() => undefined))
    const pending = renderPage(<DashboardPage />)
    expect(screen.getByRole('status')).toHaveTextContent('Loading…')
    pending.unmount()

    http.get.mockRejectedValue(new ApiError('Resource not found.', 404))
    renderPage(<DashboardPage />)
    expect(await screen.findByRole('alert')).toHaveTextContent('Resource not found.')
  })

  it('renders Arabic in an RTL document', async () => {
    await i18n.changeLanguage('ar')
    renderPage(<DashboardPage />)

    expect(document.documentElement.lang).toBe('ar')
    expect(document.documentElement.dir).toBe('rtl')
    expect(await screen.findByRole('heading', { name: 'لوحة المعلومات' })).toBeInTheDocument()
    expect(await screen.findByRole('link', { name: /حاضرون/ })).toHaveAttribute(
      'href',
      '/admin/attendance',
    )
    expect(screen.getByRole('heading', { name: 'الرحلات حسب الحالة' })).toBeInTheDocument()
  })
})

describe('admin dashboard waits for the request', () => {
  it('keeps the cards hidden until the request settles', async () => {
    let release: (value: { data: AdminDashboard }) => void = () => undefined
    http.get.mockReturnValue(
      new Promise((resolve) => {
        release = resolve
      }),
    )
    renderPage(<DashboardPage />)
    expect(screen.queryByRole('link', { name: /Total drivers/ })).not.toBeInTheDocument()
    release({ data: summary })
    await waitFor(() => {
      expect(screen.getByRole('link', { name: /Total drivers/ })).toBeInTheDocument()
    })
  })
})
