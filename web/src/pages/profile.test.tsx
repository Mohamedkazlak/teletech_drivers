import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../api/client'
import type { User } from '../api/types'
import { AuthContext } from '../auth/auth-context'
import i18n from '../i18n'
import { renderPage } from '../test/render-page'
import { ProfilePage } from './ProfilePage'

vi.mock('../api/client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

function user(role: User['role']): User {
  return {
    id: 'u1',
    name_en: 'Ada',
    name_ar: null,
    email: 'ada@test.com',
    role,
    is_active: true,
    phone: '0100',
    branch: 'company_headquarters',
    must_change_password: false,
    is_available: false,
  }
}

function renderProfile(role: User['role']) {
  return renderPage(
    <AuthContext.Provider
      value={{
        status: 'authenticated',
        user: user(role),
        login: vi.fn(),
        logout: vi.fn(),
        refresh: vi.fn(async () => user(role)),
      }}
    >
      <ProfilePage />
    </AuthContext.Provider>,
  )
}

describe('profile branch', () => {
  beforeEach(async () => {
    vi.mocked(api.patch).mockReset()
    await i18n.changeLanguage('en')
  })

  it('keeps branch read-only for a non-admin', async () => {
    const person = userEvent.setup()
    vi.mocked(api.patch).mockResolvedValue(user('company_admin'))
    renderProfile('company_admin')

    expect(screen.queryByRole('combobox', { name: 'Branch' })).not.toBeInTheDocument()
    expect(screen.getByText('Contact the admin to change your branch.')).toBeInTheDocument()
    expect(screen.getByText('Company Headquarters')).toBeInTheDocument()

    await person.click(screen.getByRole('button', { name: 'Save' }))
    await waitFor(() => expect(api.patch).toHaveBeenCalled())
    expect(vi.mocked(api.patch).mock.calls[0]?.[1]).not.toHaveProperty('branch')
  })

  it('lets a system admin edit branch', () => {
    renderProfile('admin')
    expect(screen.getByRole('combobox', { name: 'Branch' })).toBeEnabled()
  })
})
