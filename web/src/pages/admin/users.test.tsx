import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import type { User } from '../../api/types'
import type { Account } from '../../api/users'
import { AuthContext } from '../../auth/auth-context'
import i18n from '../../i18n'
import { paginated, renderPage } from '../../test/render-page'
import { UsersPage } from './UsersPage'

vi.mock('../../api/client', () => ({
  api: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), delete: vi.fn() },
}))

const http = vi.mocked(api)

const adminUser: User = {
  id: 'admin-1',
  name_en: 'System Admin',
  name_ar: null,
  email: 'admin@example.com',
  role: 'admin',
  is_active: true,
  phone: null,
  branch: null,
  must_change_password: false,
  is_available: false,
}

function account(overrides: Partial<Account> = {}): Account {
  return {
    id: 'emp-1',
    name_en: 'Sara Nabil',
    name_ar: 'سارة نبيل',
    email: 'sara@example.com',
    role: 'employee',
    is_active: true,
    phone: '01000000000',
    branch: 'company_headquarters',
    must_change_password: false,
    ...overrides,
  }
}

function renderUsers() {
  return renderPage(
    <AuthContext.Provider
      value={{
        status: 'authenticated',
        user: adminUser,
        login: vi.fn(),
        logout: vi.fn(),
        refresh: vi.fn(),
      }}
    >
      <UsersPage />
    </AuthContext.Provider>,
  )
}

describe('system admin users', () => {
  beforeEach(async () => {
    http.get.mockReset()
    http.post.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockResolvedValue(
      paginated([
        account({
          id: 'admin-1',
          name_en: 'System Admin',
          email: 'admin@example.com',
          role: 'admin',
        }),
        account(),
      ]),
    )
  })

  it('resets another account and hides the action on the signed-in admin', async () => {
    const user = userEvent.setup()
    http.post.mockResolvedValue(account({ must_change_password: true }))
    renderUsers()

    expect(await screen.findByText('Sara Nabil')).toBeInTheDocument()
    expect(screen.getByText('System Admin')).toBeInTheDocument()
    expect(screen.getAllByRole('button', { name: /^Actions for/ })).toHaveLength(1)
    expect(screen.getByText('You')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: /^Actions for/ }))
    await user.click(screen.getByRole('menuitem', { name: 'Reset password' }))
    const dialog = await screen.findByRole('dialog', { name: 'Reset password' })
    expect(
      within(dialog).getByText(/must change this password the next time they sign in/i),
    ).toBeInTheDocument()

    await user.type(within(dialog).getByLabelText('Temporary password'), 'temporary1')
    await user.type(within(dialog).getByLabelText('Confirm temporary password'), 'temporary1')
    await user.click(within(dialog).getByRole('button', { name: 'Reset password' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/users/emp-1/reset-password', {
        password: 'temporary1',
        password_confirmation: 'temporary1',
      })
    })
    expect(await screen.findByText('Temporary password saved.')).toBeInTheDocument()
  })

  it('filters the directory by role', async () => {
    const user = userEvent.setup()
    renderUsers()
    await screen.findByText('Sara Nabil')

    await user.selectOptions(screen.getByLabelText('Role'), 'driver')

    await waitFor(() => {
      expect(http.get).toHaveBeenCalledWith(
        '/users',
        expect.objectContaining({
          query: { role: 'driver', per_page: 15 },
        }),
      )
    })
  })
})
