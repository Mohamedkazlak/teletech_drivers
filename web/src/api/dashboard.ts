import { api } from './client'
import type { AdminDashboardResponse } from './types'

export function getAdminDashboard(signal?: AbortSignal) {
  return api.get<AdminDashboardResponse>('/admin/dashboard', { signal })
}
