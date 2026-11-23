import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import { ApiError } from '../../api/errors'
import i18n from '../../i18n'
import { paginated, renderPage, tripRequest } from '../../test/render-page'
import { RequestedTripsPage } from './RequestedTripsPage'

vi.mock('../../components/map/MapView', () => ({
  MapView: () => null,
}))

vi.mock('../../api/client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const http = vi.mocked(api)

function member(request: ReturnType<typeof tripRequest>, from = request.pickup.name) {
  return {
    request_id: request.id,
    requester_name_en: request.employee_name_en,
    requester_name_ar: request.employee_name_ar,
    branch: request.employee_branch,
    from_place: from,
    to_place: request.destination.name,
    requested_at: request.requested_at,
  }
}

function listQuery(call: unknown[]) {
  const options = call[1] as { query?: Record<string, unknown> } | undefined
  return call[0] === '/trip-requests' ? options?.query : undefined
}

describe('requested trips', () => {
  beforeEach(async () => {
    http.get.mockReset()
    http.post.mockReset()
    await i18n.changeLanguage('en')
  })

  it('loads pending requests and sends status and branch filters', async () => {
    const user = userEvent.setup()
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trip-requests/grouping-suggestions') return { data: [] }
      if (path === '/trip-requests') return paginated([tripRequest()])
      throw new Error(path)
    })

    renderPage(<RequestedTripsPage />)

    expect(await screen.findByText('Sara Nabil')).toBeInTheDocument()
    await waitFor(() => {
      expect(http.get).toHaveBeenCalledWith(
        '/trip-requests',
        expect.objectContaining({ query: { status: 'pending', per_page: 15 } }),
      )
    })

    await user.selectOptions(screen.getByRole('combobox', { name: 'Approval' }), 'Approved')
    await waitFor(() => {
      expect(http.get.mock.calls.map(listQuery)).toContainEqual({
        status: 'approved',
        per_page: 15,
      })
    })

    await user.selectOptions(screen.getByRole('combobox', { name: 'Branch' }), 'Company Headquarters')
    await waitFor(() => {
      expect(http.get.mock.calls.map(listQuery)).toContainEqual({
        status: 'approved',
        branch: 'company_headquarters',
        per_page: 15,
      })
    })
  })

  it('approves a pending request after confirmation', async () => {
    const user = userEvent.setup()
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trip-requests/grouping-suggestions') return { data: [] }
      if (path === '/trip-requests') return paginated([tripRequest()])
      throw new Error(path)
    })
    http.post.mockResolvedValue(tripRequest({ status: 'approved' }))

    renderPage(<RequestedTripsPage />)
    await user.click(await screen.findByRole('button', { name: 'Approve' }))
    const dialog = await screen.findByRole('dialog', { name: 'Approve this request?' })
    await user.click(within(dialog).getByRole('button', { name: 'Approve request' }))

    await waitFor(() => {
      expect(http.post.mock.calls[0]).toEqual(['/trip-requests/req-1/approve'])
    })
    expect(await screen.findByText('Request approved.')).toBeInTheDocument()
  })

  it('rejects with a reason and shows a 422 field error', async () => {
    const user = userEvent.setup()
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trip-requests/grouping-suggestions') return { data: [] }
      if (path === '/trip-requests') return paginated([tripRequest()])
      throw new Error(path)
    })
    http.post.mockRejectedValue(
      new ApiError('The given data was invalid.', 422, {
        errors: { rejection_reason: ['The reason is too long.'] },
      }),
    )

    renderPage(<RequestedTripsPage />)
    await user.click(await screen.findByRole('button', { name: 'Reject' }))
    const dialog = await screen.findByRole('dialog', { name: 'Reject this request?' })
    await user.type(within(dialog).getByLabelText('Rejection reason'), 'Schedule conflict')
    await user.click(within(dialog).getByRole('button', { name: 'Reject request' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/trip-requests/req-1/reject', {
        rejection_reason: 'Schedule conflict',
      })
    })
    expect(await within(dialog).findByRole('alert')).toHaveTextContent('The reason is too long.')
  })

  it('approves a whole group and a selected subset', async () => {
    const user = userEvent.setup()
    const first = tripRequest({ id: 'req-1', employee_name_en: 'Sara Nabil' })
    const second = tripRequest({
      id: 'req-2',
      employee_name_en: 'Omar Fathy',
      employee_name_ar: 'عمر فتحي',
    })
    const third = tripRequest({
      id: 'req-3',
      employee_name_en: 'Lina Adel',
      employee_name_ar: 'لينا عادل',
    })
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trip-requests/grouping-suggestions') {
        return {
          data: [
            {
              cluster_id: 'cluster-1',
              request_ids: ['req-1', 'req-2'],
              destination_label: 'Site',
              route_label: 'HQ to site',
              date: '2026-12-01',
              earliest_requested_at: '2026-12-01T08:00:00.000Z',
              latest_requested_at: '2026-12-01T09:00:00.000Z',
              members: [member(first, 'North gate'), member(second)],
            },
            {
              cluster_id: 'cluster-2',
              request_ids: ['req-1', 'req-2', 'req-3'],
              destination_label: 'Plant',
              route_label: 'HQ to plant',
              date: '2026-12-02',
              earliest_requested_at: '2026-12-02T08:00:00.000Z',
              latest_requested_at: '2026-12-02T09:00:00.000Z',
              members: [member(first), member(second), member(third)],
            },
          ],
        }
      }
      if (path === '/trip-requests') return paginated([first, second, third])
      throw new Error(path)
    })
    http.post.mockResolvedValue({ data: [] })

    renderPage(<RequestedTripsPage />)
    const whole = await screen.findByRole('article', { name: 'HQ to site' })
    expect(within(whole).getByText(/North gate to Site/)).toBeInTheDocument()
    await user.click(within(whole).getByRole('button', { name: 'Approve group' }))
    const dialog = await screen.findByRole('dialog', { name: 'Approve these requests together?' })
    await user.click(within(dialog).getByRole('button', { name: 'Approve group' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/trip-requests/approve-group', {
        request_ids: ['req-1', 'req-2'],
      })
    })

    const subset = screen.getByRole('article', { name: 'HQ to plant' })
    await user.click(within(subset).getByRole('checkbox', { name: 'Sara Nabil' }))
    await user.click(within(subset).getByRole('button', { name: 'Approve selected' }))
    const secondDialog = await screen.findByRole('dialog', {
      name: 'Approve these requests together?',
    })
    await user.click(within(secondDialog).getByRole('button', { name: 'Approve group' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/trip-requests/approve-group', {
        request_ids: ['req-2', 'req-3'],
      })
    })
  })

  it('shows a forbidden list error', async () => {
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trip-requests/grouping-suggestions') return { data: [] }
      throw new ApiError('Forbidden.', 403)
    })

    renderPage(<RequestedTripsPage />)
    expect(await screen.findByRole('alert')).toHaveTextContent('Forbidden.')
  })

  it('renders Arabic from right to left', async () => {
    http.get.mockImplementation(async (path: string) => {
      if (path === '/trip-requests/grouping-suggestions') return { data: [] }
      if (path === '/trip-requests') return paginated([tripRequest()])
      throw new Error(path)
    })
    await i18n.changeLanguage('ar')

    renderPage(<RequestedTripsPage />)

    expect(document.documentElement.dir).toBe('rtl')
    expect(await screen.findByRole('heading', { name: 'الرحلات المطلوبة' })).toBeInTheDocument()
    expect(await screen.findByText('سارة نبيل')).toBeInTheDocument()
  })
})
