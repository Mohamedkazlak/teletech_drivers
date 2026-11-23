import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { retryTransient } from './retry'
import {
  createEmployee,
  deleteEmployee,
  listEmployees,
  restoreEmployee,
  updateEmployee,
  type CreateEmployeeBody,
  type ListEmployeesQuery,
  type UpdateEmployeeBody,
} from './employees'

export const employeeKeys = {
  all: ['employees'] as const,
  list: (query: ListEmployeesQuery) => ['employees', 'list', query] as const,
}

function invalidateEmployees(queryClient: ReturnType<typeof useQueryClient>) {
  void queryClient.invalidateQueries({ queryKey: employeeKeys.all })
}

export function useEmployees(query: ListEmployeesQuery) {
  return useQuery({
    queryKey: employeeKeys.list(query),
    queryFn: ({ signal }) => listEmployees(query, signal),
    retry: retryTransient,
  })
}

export function useCreateEmployee() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (body: CreateEmployeeBody) => createEmployee(body),
    onSuccess: () => invalidateEmployees(queryClient),
  })
}

export function useUpdateEmployee() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: UpdateEmployeeBody }) =>
      updateEmployee(id, body),
    onSuccess: () => invalidateEmployees(queryClient),
  })
}

export function useDeleteEmployee() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => deleteEmployee(id),
    onSuccess: () => invalidateEmployees(queryClient),
  })
}

export function useRestoreEmployee() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => restoreEmployee(id),
    onSuccess: () => invalidateEmployees(queryClient),
  })
}
