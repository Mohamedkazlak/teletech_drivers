import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { listUsers, resetUserPassword, type ListUsersQuery } from './users'
import { retryTransient } from './retry'

export const userKeys = {
  all: ['users'] as const,
  list: (query: ListUsersQuery) => ['users', 'list', query] as const,
}

export function useUsers(query: ListUsersQuery) {
  return useQuery({
    queryKey: userKeys.list(query),
    queryFn: ({ signal }) => listUsers(query, signal),
    retry: retryTransient,
  })
}

export function useResetUserPassword() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, password }: { id: string; password: string }) =>
      resetUserPassword(id, password),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: userKeys.all })
    },
  })
}
