import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import { ApiError } from '../../api/errors'
import type { Employee } from '../../api/types'
import i18n from '../../i18n'
import { paginated, renderPage } from '../../test/render-page'
import { EmployeesPage } from './EmployeesPage'

vi.mock('../../api/client', () => ({
  api: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), delete: vi.fn() },
}))

const http = vi.mocked(api)

function employee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'emp-1',
    name_en: 'Sara Nabil',
    name_ar: 'سارة نبيل',
    email: 'sara@example.com',
    role: 'employee',
    is_active: true,
    phone: '01000000000',
    branch: 'company_headquarters',
    deleted_at: null,
    deleted_by: null,
    ...overrides,
  }
}

function queriesFor(path: string) {
  return http.get.mock.calls
    .filter((call) => call[0] === path)
    .map((call) => (call[1] as { query?: Record<string, unknown> } | undefined)?.query)
}

async function fillCreate(user: ReturnType<typeof userEvent.setup>) {
  await user.click(screen.getByRole('button', { name: 'Add employee' }))
  const dialog = await screen.findByRole('dialog', { name: 'Add employee' })
  await user.type(within(dialog).getByLabelText('Name (English)'), 'Huda Samir')
  await user.type(within(dialog).getByLabelText('Name (Arabic)'), 'هدى سمير')
  await user.type(within(dialog).getByLabelText('Email'), 'huda@example.com')
  await user.type(within(dialog).getByLabelText('Phone'), '01022222222')
  await user.selectOptions(within(dialog).getByLabelText('Branch'), 'new_headquarters')
  await user.type(within(dialog).getByLabelText('Temporary password'), 'password1')
  return dialog
}

describe('employees', () => {
  beforeEach(async () => {
    http.get.mockReset()
    http.post.mockReset()
    http.patch.mockReset()
    http.delete.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockImplementation(
      async (path: string, options?: { query?: { include_deleted?: boolean } }) => {
        if (path !== '/employees') throw new Error(path)
        if (options?.query?.include_deleted) {
          return paginated([
            employee({ deleted_at: '2026-11-01T00:00:00.000Z', deleted_by: 'admin-1' }),
          ])
        }
        return paginated([employee()])
      },
    )
  })

  afterEach(async () => {
    await i18n.changeLanguage('en')
  })

  it('filters by search, branch, account, and deleted rows', async () => {
    const user = userEvent.setup()
    renderPage(<EmployeesPage />, '/?search=sara&branch=company_headquarters&active=true')

    await waitFor(() => {
      expect(queriesFor('/employees')).toContainEqual({
        search: 'sara',
        branch: 'company_headquarters',
        is_active: true,
        per_page: 15,
      })
    })
    expect(screen.getByRole('switch', { name: 'Include deleted' })).not.toBeChecked()

    await user.selectOptions(screen.getByRole('combobox', { name: 'Account' }), 'Inactive')
    await user.selectOptions(screen.getByRole('combobox', { name: 'Branch' }), 'New Headquarters')
    await user.click(screen.getByRole('switch', { name: 'Include deleted' }))

    await waitFor(() => {
      expect(queriesFor('/employees')).toContainEqual(
        expect.objectContaining({
          search: 'sara',
          branch: 'new_headquarters',
          is_active: false,
          include_deleted: true,
        }),
      )
    })
    expect(await screen.findByRole('button', { name: 'Restore' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Edit' })).not.toBeInTheDocument()
  })

  it('creates an employee and shows a 422 field error', async () => {
    const user = userEvent.setup()
    http.post.mockRejectedValueOnce(
      new ApiError('The given data was invalid.', 422, {
        errors: { email: ['The email has already been taken.'] },
      }),
    )
    http.post.mockResolvedValueOnce(employee({ id: 'emp-2', email: 'huda@example.com' }))
    renderPage(<EmployeesPage />)

    const dialog = await fillCreate(user)
    await user.click(within(dialog).getByRole('button', { name: 'Save' }))
    expect(await within(dialog).findByText('The email has already been taken.')).toBeInTheDocument()
    expect(http.post).toHaveBeenCalledWith('/employees', {
      name_en: 'Huda Samir',
      name_ar: 'هدى سمير',
      email: 'huda@example.com',
      phone: '01022222222',
      branch: 'new_headquarters',
      password: 'password1',
    })

    await user.click(within(dialog).getByRole('button', { name: 'Save' }))
    expect(await screen.findByText('Employee added.')).toBeInTheDocument()
  })

  it('sends only the changed fields when an employee is edited', async () => {
    const user = userEvent.setup()
    http.patch.mockResolvedValue(employee({ phone: '01099999999' }))
    renderPage(<EmployeesPage />)

    await user.click(await screen.findByRole('button', { name: 'Edit' }))
    const dialog = await screen.findByRole('dialog', { name: 'Edit employee' })
    expect(within(dialog).queryByLabelText('Temporary password')).not.toBeInTheDocument()
    const phone = within(dialog).getByLabelText('Phone')
    await user.clear(phone)
    await user.type(phone, '01099999999')
    await user.click(within(dialog).getByRole('button', { name: 'Save' }))

    await waitFor(() => {
      expect(http.patch).toHaveBeenCalledWith('/employees/emp-1', { phone: '01099999999' })
    })
  })

  it('deletes and restores only after confirmation', async () => {
    const user = userEvent.setup()
    http.delete.mockResolvedValue(employee())
    http.post.mockResolvedValue(employee({ deleted_at: null }))
    renderPage(<EmployeesPage />)

    await user.click(await screen.findByRole('button', { name: 'Delete' }))
    const deleteDialog = await screen.findByRole('dialog', { name: 'Delete this employee?' })
    await user.click(within(deleteDialog).getByRole('button', { name: 'Delete' }))
    await waitFor(() => {
      expect(http.delete).toHaveBeenCalledWith('/employees/emp-1')
    })

    await user.click(screen.getByRole('switch', { name: 'Include deleted' }))
    await user.click(await screen.findByRole('button', { name: 'Restore' }))
    const restoreDialog = await screen.findByRole('dialog', { name: 'Restore this employee?' })
    await user.click(within(restoreDialog).getByRole('button', { name: 'Restore' }))
    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/employees/emp-1/restore')
    })
    expect(await screen.findByText('Employee restored.')).toBeInTheDocument()
  })

  it('uses Arabic labels in an RTL document', async () => {
    await i18n.changeLanguage('ar')
    renderPage(<EmployeesPage />)
    expect(document.documentElement.dir).toBe('rtl')
    expect(await screen.findByRole('heading', { name: 'الموظفون' })).toBeInTheDocument()
    expect(screen.getByLabelText('بحث في الموظفين')).toBeInTheDocument()
    expect(screen.getByRole('switch', { name: 'إظهار المحذوف' })).toBeInTheDocument()
  })
})
