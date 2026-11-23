import { api } from './client'
import { PAGE_SIZE, toQuery } from './to-query'
import type { Branch, Paginated, UserRole } from './types'

export type Account = {
  id: string
  name_en: string
  name_ar: string | null
  email: string
  role: UserRole
  is_active: boolean
  phone: string | null
  branch: Branch | null
  must_change_password: boolean
}

export type ListUsersQuery = {
  role?: UserRole
  search?: string
  page?: number
  per_page?: number
}

export type UserListFilters = {
  search: string
  role: UserRole | ''
  page: number
}

export function usersListQuery(input: UserListFilters): ListUsersQuery {
  return {
    search: input.search.trim() || undefined,
    role: input.role || undefined,
    page: input.page > 1 ? input.page : undefined,
    per_page: PAGE_SIZE,
  }
}

export function listUsers(query: ListUsersQuery, signal?: AbortSignal) {
  return api.get<Paginated<Account>>('/users', { query: toQuery(query), signal })
}

export function resetUserPassword(id: string, password: string) {
  return api.post<Account>(`/users/${id}/reset-password`, {
    password,
    password_confirmation: password,
  })
}
