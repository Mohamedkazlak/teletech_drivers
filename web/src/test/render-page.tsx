import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, type RenderOptions } from '@testing-library/react'
import type { ReactElement, ReactNode } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { ToastProvider } from '../components/ui/ToastProvider'
import type { Driver, PageMeta, Paginated, Place, TripRequest, TripSummary } from '../api/types'

export function renderPage(ui: ReactElement, path = '/', options?: Omit<RenderOptions, 'wrapper'>) {
  const client = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  })
  function Wrapper({ children }: { children: ReactNode }) {
    return (
      <QueryClientProvider client={client}>
        <MemoryRouter initialEntries={[path]}>
          <ToastProvider>{children}</ToastProvider>
        </MemoryRouter>
      </QueryClientProvider>
    )
  }
  return render(ui, { wrapper: Wrapper, ...options })
}

export function pageMeta(total: number, page = 1): PageMeta {
  return { current_page: page, per_page: 15, last_page: Math.max(1, Math.ceil(total / 15)), total }
}

export function paginated<T>(data: T[], page = 1): Paginated<T> {
  return { data, meta: pageMeta(data.length, page) }
}

export function tripRequest(overrides: Partial<TripRequest> = {}): TripRequest {
  return {
    id: 'req-1',
    employee_id: 'emp-1',
    employee_name_en: 'Sara Nabil',
    employee_name_ar: 'سارة نبيل',
    employee_phone: '01000000000',
    employee_branch: 'company_headquarters',
    requester_role: 'employee',
    pickup: { place_id: 'place-1', name: 'HQ', lat: 30.05, lng: 31.24, address: null },
    destination: { place_id: 'place-2', name: 'Site', lat: 30.08, lng: 31.3, address: null },
    requested_at: '2026-12-01T08:00:00.000Z',
    notes: 'Two passengers',
    status: 'pending',
    trip_id: null,
    trip_status: null,
    rejection_reason: null,
    handled_by: null,
    handled_at: null,
    auto_approved: false,
    suggested_group_id: null,
    created_at: '2026-11-01T08:00:00.000Z',
    trip: null,
    tracking: null,
    ...overrides,
  }
}

export function place(overrides: Partial<Place> = {}): Place {
  return {
    id: 'place-1',
    name_en: 'Headquarters',
    name_ar: 'المقر',
    latitude: 30.05,
    longitude: 31.24,
    address: 'Main road',
    is_headquarters: true,
    is_active: true,
    created_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}

export function driver(overrides: Partial<Driver> = {}): Driver {
  return {
    id: 'driver-1',
    name_en: 'Nader Ali',
    name_ar: 'نادر علي',
    email: 'nader@example.com',
    role: 'driver',
    is_active: true,
    phone: '01011111111',
    is_available: true,
    favorite_place_ids: [],
    deleted_at: null,
    deleted_by: null,
    national_id: '12345678901234',
    car_license: 'ط ع ب 9295',
    personal_license: 'PER-1',
    ...overrides,
  }
}

export function tripSummary(overrides: Partial<TripSummary> = {}): TripSummary {
  return {
    id: 'trip-1',
    driver_id: null,
    driver: null,
    scheduled_at: '2026-11-11T08:00:00.000Z',
    status: 'unassigned',
    created_by: 'admin-1',
    pickup_summary: 'HQ',
    destination_summary: 'Site',
    going_started_at: null,
    going_ended_at: null,
    return_started_at: null,
    finished_at: null,
    going_distance_m: null,
    return_distance_m: null,
    total_distance_m: null,
    confirmation_status: null,
    confirmation_requested_at: null,
    confirmed_at: null,
    driver_showed_up: null,
    confirmation_note: null,
    passengers: [],
    passengers_branches: [],
    created_at: '2026-11-01T00:00:00.000Z',
    tracking: null,
    ...overrides,
  }
}
