import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import { ApiError } from '../../api/errors'
import i18n from '../../i18n'
import { formatDateParam } from '../../lib/period'
import { paginated, renderPage, tripRequest } from '../../test/render-page'
import { TripRequestsPage } from './TripRequestsPage'

vi.mock('../../components/map/MapView', () => ({
  MapView: () => null,
}))

vi.mock('../../api/client', () => ({
  api: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), delete: vi.fn() },
}))

const http = vi.mocked(api)

function queriesFor(path: string) {
  return http.get.mock.calls
    .filter((call) => call[0] === path)
    .map((call) => (call[1] as { query?: Record<string, unknown> } | undefined)?.query)
}

describe('admin trip requests', () => {
  beforeEach(async () => {
    http.get.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trip-requests') return paginated([tripRequest()])
      throw new Error(path)
    })
  })

  it('lists requests with status, branch, and period, and stays read-only', async () => {
    const user = userEvent.setup()
    renderPage(<TripRequestsPage />)

    await waitFor(() => {
      expect(queriesFor('/trip-requests')).toContainEqual({ status: 'pending', per_page: 15 })
    })
    expect(screen.queryByRole('button', { name: 'Approve' })).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Reject' })).not.toBeInTheDocument()
    expect(await screen.findByText('Sara Nabil')).toBeInTheDocument()

    await user.selectOptions(screen.getByRole('combobox', { name: 'Status' }), 'Approved')
    await user.selectOptions(screen.getByRole('combobox', { name: 'Branch' }), 'New Headquarters')
    await user.selectOptions(screen.getByRole('combobox', { name: 'Period' }), 'Week')

    const today = formatDateParam(new Date())
    await waitFor(() => {
      expect(queriesFor('/trip-requests')).toContainEqual({
        status: 'approved',
        branch: 'new_headquarters',
        period: 'week',
        date: today,
        per_page: 15,
      })
    })

    await user.click(screen.getByRole('button', { name: 'View' }))
    const dialog = await screen.findByRole('dialog', { name: 'Request details' })
    expect(within(dialog).getByText('Two passengers')).toBeInTheDocument()
    expect(within(dialog).queryByRole('button', { name: 'Approve' })).not.toBeInTheDocument()
    expect(http.get.mock.calls.map((call) => call[0])).not.toContain('/trip-requests/req-1')
  })

  it('shows a clear forbidden message', async () => {
    http.get.mockRejectedValue(new ApiError('Forbidden.', 403))
    renderPage(<TripRequestsPage />)
    expect(await screen.findByRole('alert')).toHaveTextContent('Forbidden.')
  })
})
