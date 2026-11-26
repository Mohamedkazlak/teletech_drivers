import { screen, waitFor, within } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../api/client'
import { ApiError } from '../api/errors'
import type { AdminDashboard } from '../api/types'
import i18n from '../i18n'
import { paginated, renderPage, tripSummary } from '../test/render-page'
import { DashboardPage } from './DashboardPage'

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

const zero: AdminDashboard = {
  drivers: { total: 10, checked_in: 10, checked_out: 0, absent: 0 },
  employees_total: 0,
  places_total: 0,
  trips: { unassigned: 0, assigned: 0, in_progress: 0, completed_today: 0, completed_this_week: 0 },
  requests: { pending: 0, approved: 0, rejected: 0 },
  unconfirmed_trips: 0,
}

function respond(
  dashboard: AdminDashboard,
  onTheRoad = [
    tripSummary({
      status: 'going',
      pickup_summary: 'Cairo HQ',
      destination_summary: 'Smart Village',
    }),
  ],
) {
  http.get.mockImplementation(async (path: string) => {
    if (path === '/admin/dashboard') return { data: dashboard }
    if (path === '/trips') return paginated(onTheRoad)
    throw new Error(path)
  })
}

describe('admin dashboard', () => {
  beforeEach(async () => {
    http.get.mockReset()
    await i18n.changeLanguage('en')
    respond(summary)
  })

  afterEach(async () => {
    await i18n.changeLanguage('en')
  })

  it('puts what needs action first and links each item to its list', async () => {
    renderPage(<DashboardPage />)
    const attention = await screen.findByRole('region', { name: 'Needs attention' })
    expect(within(attention).getByRole('link', { name: /Unassigned trips\s+2/ })).toHaveAttribute(
      'href',
      '/admin/trips?stage=unassigned',
    )
    expect(within(attention).getByRole('link', { name: /Pending requests\s+8/ })).toHaveAttribute(
      'href',
      '/admin/trip-requests?status=pending',
    )
    expect(within(attention).getByRole('link', { name: /Unconfirmed trips\s+14/ })).toHaveAttribute(
      'href',
      '/admin/trips?unconfirmed=true',
    )
    expect(within(attention).getByRole('link', { name: /Absent drivers\s+3/ })).toHaveAttribute(
      'href',
      '/admin/attendance?status=absent',
    )
    expect(http.get).toHaveBeenCalledWith('/admin/dashboard', expect.any(Object))
  })

  it('shows the totals on one line', async () => {
    renderPage(<DashboardPage />)
    const totals = await screen.findByRole('region', { name: 'Totals' })
    expect(within(totals).getByRole('link', { name: /10\s+drivers/ })).toHaveAttribute(
      'href',
      '/admin/drivers',
    )
    expect(within(totals).getByRole('link', { name: /12\s+employees/ })).toHaveAttribute(
      'href',
      '/admin/employees',
    )
    expect(within(totals).getByRole('link', { name: /3\s+places/ })).toHaveAttribute(
      'href',
      '/admin/places',
    )
    expect(within(totals).getByRole('link', { name: /7\s+completed today/ })).toBeInTheDocument()
    expect(
      within(totals).getByRole('link', { name: /9\s+completed this week/ }),
    ).toBeInTheDocument()
  })

  it('stays calm when nothing needs action', async () => {
    respond(zero)
    renderPage(<DashboardPage />)
    const attention = await screen.findByRole('region', { name: 'Needs attention' })
    expect(within(attention).getAllByText('All clear')).toHaveLength(4)
    expect(attention.querySelector('[data-tone="warning"]')).toBeNull()
  })

  it('lists the trips on the road now', async () => {
    renderPage(<DashboardPage />)
    const road = await screen.findByRole('region', { name: 'On the road now' })
    expect(await within(road).findByText('Smart Village')).toBeInTheDocument()
    expect(within(road).getByRole('link', { name: 'View all' })).toHaveAttribute(
      'href',
      '/admin/trips?stage=in_progress',
    )
    const tripsQuery = http.get.mock.calls.find(([path]) => path === '/trips')?.[1] as
      { query?: Record<string, unknown> } | undefined
    expect(tripsQuery?.query).toMatchObject({ stage: 'in_progress', per_page: 5 })
  })

  it('says so when no trip is on the road', async () => {
    respond(summary, [])
    renderPage(<DashboardPage />)
    expect(await screen.findByText('No trips on the road right now.')).toBeInTheDocument()
  })

  it('shows a loading state and a clear not-found error', async () => {
    http.get.mockImplementation(() => new Promise(() => undefined))
    const pending = renderPage(<DashboardPage />)
    expect(screen.getAllByRole('status')[0]).toHaveTextContent('Loading…')
    pending.unmount()

    http.get.mockRejectedValue(new ApiError('Resource not found.', 404))
    renderPage(<DashboardPage />)
    expect((await screen.findAllByRole('alert'))[0]).toHaveTextContent('Resource not found.')
  })

  it('renders Arabic in an RTL document', async () => {
    await i18n.changeLanguage('ar')
    renderPage(<DashboardPage />)

    expect(document.documentElement.lang).toBe('ar')
    expect(document.documentElement.dir).toBe('rtl')
    expect(await screen.findByRole('heading', { name: 'لوحة المعلومات' })).toBeInTheDocument()
    expect(await screen.findByRole('link', { name: /سائقون غائبون/ })).toHaveAttribute(
      'href',
      '/admin/attendance?status=absent',
    )
  })
})

describe('admin dashboard waits for the request', () => {
  it('keeps the attention strip hidden until the request settles', async () => {
    let release: (value: { data: AdminDashboard }) => void = () => undefined
    http.get.mockImplementation((path: string) => {
      if (path === '/trips') return Promise.resolve(paginated([]))
      return new Promise((resolve) => {
        release = resolve
      })
    })
    renderPage(<DashboardPage />)
    expect(screen.queryByRole('region', { name: 'Needs attention' })).not.toBeInTheDocument()
    release({ data: summary })
    await waitFor(() => {
      expect(screen.getByRole('region', { name: 'Needs attention' })).toBeInTheDocument()
    })
  })
})
