import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import type { ReactNode } from 'react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import type { User } from '../../api/types'
import { AuthContext } from '../../auth/auth-context'
import { NotificationMenu } from './NotificationMenu'
import i18n from '../../i18n'
import { pageMeta } from '../../test/render-page'

vi.mock('../../api/client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const http = vi.mocked(api)

const notification = {
  id: 'note-1',
  type: 'request_submitted',
  title_key: 'notifications.request_submitted.title',
  body_key: 'notifications.request_submitted.body',
  params: {
    requester_name_en: 'Mona',
    requester_name_ar: 'منى',
    pickup: 'HQ',
    destination: 'Site',
  },
  trip_request_id: 'req-1',
  trip_id: null,
  read_at: null,
  created_at: '2026-11-16T12:00:00.000Z',
}

function user(): User {
  return {
    id: 'admin-1',
    name_en: 'Ada',
    name_ar: null,
    email: 'ada@test.com',
    role: 'company_admin',
    is_active: true,
    phone: '0100',
    branch: 'company_headquarters',
    must_change_password: false,
    is_available: false,
  }
}

function renderMenu() {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  })
  function Wrapper({ children }: { children: ReactNode }) {
    return (
      <QueryClientProvider client={client}>
        <AuthContext.Provider
          value={{
            status: 'authenticated',
            user: user(),
            login: vi.fn(),
            logout: vi.fn(),
            refresh: vi.fn(async () => user()),
          }}
        >
          <MemoryRouter>
            <Routes>
              <Route path="/" element={children} />
              <Route path="/company-admin" element={<p>requested-trips</p>} />
              <Route path="/notifications" element={<p>all-notifications</p>} />
            </Routes>
          </MemoryRouter>
        </AuthContext.Provider>
      </QueryClientProvider>
    )
  }
  return render(<NotificationMenu />, { wrapper: Wrapper })
}

describe('notification menu', () => {
  beforeEach(async () => {
    http.get.mockReset()
    http.post.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockImplementation(async (path: string) => {
      if (path === '/notifications/unread-count') return { count: 2 }
      if (path === '/notifications') {
        return { data: [notification], meta: pageMeta(1) }
      }
      throw new Error(path)
    })
    http.post.mockResolvedValue({ ...notification, read_at: '2026-11-16T12:05:00.000Z' })
  })

  it('shows the unread badge, renders the key, and deep-links after marking read', async () => {
    const person = userEvent.setup()
    renderMenu()

    expect(await screen.findByText('2')).toBeInTheDocument()
    await person.click(screen.getByRole('button', { name: 'Notifications' }))
    expect(await screen.findByText('New trip request')).toBeInTheDocument()
    expect(screen.getByText('Mona requested a trip from HQ to Site.')).toBeInTheDocument()

    await person.click(screen.getByRole('menuitem', { name: /New trip request/ }))
    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/notifications/note-1/read')
    })
    expect(await screen.findByText('requested-trips')).toBeInTheDocument()
  })

  it('links to the full list', async () => {
    const person = userEvent.setup()
    renderMenu()
    await person.click(await screen.findByRole('button', { name: 'Notifications' }))
    await person.click(await screen.findByRole('menuitem', { name: 'View all' }))
    expect(await screen.findByText('all-notifications')).toBeInTheDocument()
  })
})
