import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useForegroundPoll } from '../lib/use-foreground-poll'
import {
  adjustAttendance,
  attendanceQr,
  attendanceSummary,
  driverAttendance,
  listAttendance,
  type AdjustAttendanceBody,
  type ListAttendanceQuery,
} from './attendance'
import { retryTransient } from './retry'

export const attendanceKeys = {
  all: ['attendance'] as const,
  list: (query: ListAttendanceQuery) => ['attendance', 'list', query] as const,
  summary: ['attendance', 'summary'] as const,
  driver: (driverId: string, query: ListAttendanceQuery) =>
    ['attendance', 'driver', driverId, query] as const,
  qr: ['attendance', 'qr'] as const,
}

export function useAttendanceList(query: ListAttendanceQuery) {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: attendanceKeys.list(query),
    queryFn: ({ signal }) => listAttendance(query, signal),
    refetchInterval: pollMs,
    refetchIntervalInBackground: false,
    retry: retryTransient,
  })
}

export function useAttendanceSummary() {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: attendanceKeys.summary,
    queryFn: ({ signal }) => attendanceSummary(signal),
    refetchInterval: pollMs,
    refetchIntervalInBackground: false,
    retry: retryTransient,
  })
}

export function useDriverAttendance(driverId: string, query: ListAttendanceQuery) {
  const pollMs = useForegroundPoll()
  return useQuery({
    queryKey: attendanceKeys.driver(driverId, query),
    queryFn: ({ signal }) => driverAttendance(driverId, query, signal),
    enabled: driverId.length > 0,
    refetchInterval: pollMs,
    refetchIntervalInBackground: false,
    retry: retryTransient,
  })
}

export function useAttendanceQr() {
  return useQuery({
    queryKey: attendanceKeys.qr,
    queryFn: ({ signal }) => attendanceQr(signal),
    retry: retryTransient,
  })
}

export function useAdjustAttendance() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (body: AdjustAttendanceBody) => adjustAttendance(body),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: attendanceKeys.all })
    },
  })
}
