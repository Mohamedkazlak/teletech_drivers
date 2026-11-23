import { api } from './client'
import { PAGE_SIZE, toQuery } from './to-query'
import type { Branch, Employee, Paginated } from './types'

export type ListEmployeesQuery = {
  is_active?: boolean
  branch?: Branch
  search?: string
  include_deleted?: boolean
  page?: number
  per_page?: number
}

export type CreateEmployeeBody = {
  name_en: string
  name_ar: string
  email: string
  password: string
  phone: string | null
  branch: Branch | null
}

export type UpdateEmployeeBody = {
  name_en?: string
  name_ar?: string | null
  email?: string
  phone?: string | null
  branch?: Branch | null
  password?: string
}

export type EmployeeListFilters = {
  search: string
  branch: Branch | ''
  active: '' | 'true' | 'false'
  includeDeleted: boolean
  page: number
}

export function employeesListQuery(input: EmployeeListFilters): ListEmployeesQuery {
  return {
    search: input.search.trim() || undefined,
    branch: input.branch || undefined,
    is_active: input.active === '' ? undefined : input.active === 'true',
    include_deleted: input.includeDeleted ? true : undefined,
    page: input.page > 1 ? input.page : undefined,
    per_page: PAGE_SIZE,
  }
}

export function listEmployees(query: ListEmployeesQuery, signal?: AbortSignal) {
  return api.get<Paginated<Employee>>('/employees', { query: toQuery(query), signal })
}

export function createEmployee(body: CreateEmployeeBody) {
  return api.post<Employee>('/employees', body)
}

export function updateEmployee(id: string, body: UpdateEmployeeBody) {
  return api.patch<Employee>(`/employees/${id}`, body)
}

export function deleteEmployee(id: string) {
  return api.delete<Employee>(`/employees/${id}`)
}

export function restoreEmployee(id: string) {
  return api.post<Employee>(`/employees/${id}/restore`)
}
