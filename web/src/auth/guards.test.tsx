import { render, screen } from '@testing-library/react'
import type { ReactNode } from 'react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'
import type { User } from '../api/types'
import { AuthContext, type AuthContextValue } from './auth-context'
import { RequireAuth, RequireRole } from './guards'

function makeUser(role: User['role'], extra?: Partial<User>): User {
  return {
    id: 'user-1',
    name_en: 'Mona Adel',
    name_ar: 'منى عادل',
    email: 'mona@example.com',
    role,
    is_active: true,
    phone: null,
    branch: 'company_headquarters',
    must_change_password: false,
    is_available: true,
    ...extra,
  }
}

function authValue(partial: Pick<AuthContextValue, 'status' | 'user'>): AuthContextValue {
  return {
    ...partial,
    login: vi.fn(),
    logout: vi.fn(),
    refresh: vi.fn(),
  }
}

function renderAt(path: string, value: AuthContextValue) {
  function Shell({ children }: { children: ReactNode }) {
    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
  }

  return render(
    <MemoryRouter initialEntries={[path]}>
      <Shell>
        <Routes>
          <Route path="/login" element={<p>login-screen</p>} />
          <Route
            path="/change-password"
            element={
              <RequireAuth allowPasswordChange>
                <p>change-screen</p>
              </RequireAuth>
            }
          />
          <Route
            path="/admin"
            element={
              <RequireAuth>
                <RequireRole role="admin">
                  <p>admin-home</p>
                </RequireRole>
              </RequireAuth>
            }
          />
          <Route
            path="/company-admin"
            element={
              <RequireAuth>
                <RequireRole role="company_admin">
                  <p>company-home</p>
                </RequireRole>
              </RequireAuth>
            }
          />
          <Route
            path="/drivers-admin"
            element={
              <RequireAuth>
                <RequireRole role="drivers_admin">
                  <p>drivers-home</p>
                </RequireRole>
              </RequireAuth>
            }
          />
        </Routes>
      </Shell>
    </MemoryRouter>,
  )
}

describe('auth guard', () => {
  it('sends an anonymous visitor to login', () => {
    renderAt('/admin', authValue({ status: 'anonymous', user: null }))
    expect(screen.getByText('login-screen')).toBeInTheDocument()
  })

  it('shows a loading state while the session is resolving', () => {
    renderAt('/admin', authValue({ status: 'loading', user: null }))
    expect(screen.getByRole('status')).toHaveTextContent('Loading…')
  })

  it('lets a system admin open the admin home', () => {
    renderAt('/admin', authValue({ status: 'authenticated', user: makeUser('admin') }))
    expect(screen.getByText('admin-home')).toBeInTheDocument()
  })

  it('sends a company admin away from the system admin home', () => {
    renderAt('/admin', authValue({ status: 'authenticated', user: makeUser('company_admin') }))
    expect(screen.getByText('company-home')).toBeInTheDocument()
  })

  it('lets a drivers admin open their home', () => {
    renderAt(
      '/drivers-admin',
      authValue({ status: 'authenticated', user: makeUser('drivers_admin') }),
    )
    expect(screen.getByText('drivers-home')).toBeInTheDocument()
  })

  it('forces a password change before any other page', () => {
    renderAt(
      '/admin',
      authValue({
        status: 'authenticated',
        user: makeUser('admin', { must_change_password: true }),
      }),
    )
    expect(screen.getByText('change-screen')).toBeInTheDocument()
  })

  it('keeps the change-password page available while the change is required', () => {
    renderAt(
      '/change-password',
      authValue({
        status: 'authenticated',
        user: makeUser('drivers_admin', { must_change_password: true }),
      }),
    )
    expect(screen.getByText('change-screen')).toBeInTheDocument()
  })
})
