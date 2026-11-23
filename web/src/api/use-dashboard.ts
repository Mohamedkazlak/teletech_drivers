import { useQuery } from '@tanstack/react-query'
import { useForegroundPoll } from '../lib/use-foreground-poll'
import { getAdminDashboard } from './dashboard'
import { retryTransient } from './retry'

export function useAdminDashboard() {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: ['admin-dashboard'],
    queryFn: ({ signal }) => getAdminDashboard(signal),
    refetchInterval: pollMs,
    refetchIntervalInBackground: false,
    retry: retryTransient,
  })
}
