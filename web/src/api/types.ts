export type UserRole = 'admin' | 'company_admin' | 'drivers_admin' | 'driver' | 'employee'

export type WebRole = 'admin' | 'company_admin' | 'drivers_admin'

export type Branch = 'company_headquarters' | 'new_headquarters'

export type AvailabilityStatus = 'available' | 'unavailable'

export type AvailabilityRequestStatus = AvailabilityStatus | 'finished_today'

export type TripRequestStatus = 'pending' | 'approved' | 'rejected' | 'cancelled'

export type TripStatus =
  'unassigned' | 'assigned' | 'going' | 'at_destination' | 'returning' | 'completed' | 'cancelled'

export type TripStage =
  'unassigned' | 'assigned' | 'in_progress' | 'awaiting_report' | 'completed' | 'cancelled'

export type TripRequestStage = 'needs_driver' | 'assigned'

export type TripConfirmationStatus = 'pending' | 'confirmed' | 'unconfirmed'

export type ListBucket = 'active' | 'completed' | 'cancelled'

export type FleetPeriod = 'week' | 'month' | 'year' | 'all'

export type HqDistanceBand = 'near' | 'medium' | 'far' | 'unknown'

export type LiveMapState = 'on_trip' | 'available' | 'unavailable'

export type AvailabilityRequestState = 'pending' | 'approved' | 'rejected' | 'cancelled'

export type TripCreationMode = 'one_per_request' | 'grouped'

export type PageMeta = {
  current_page: number
  per_page: number
  last_page: number
  total: number
}

export type Paginated<T> = {
  data: T[]
  meta: PageMeta
}

export type DataEnvelope<T> = {
  data: T[]
}

export type MessageResponse = {
  message: string
}

export type User = {
  id: string
  name_en: string
  name_ar: string | null
  email: string
  role: UserRole
  is_active: boolean
  phone: string | null
  branch: Branch | null
  must_change_password: boolean
  is_available: boolean
}

export type AuthTokenResponse = {
  token: string
  token_type: 'Bearer'
  user: User
}

export type LoginBody = {
  email: string
  password: string
}

export type ChangePasswordBody = {
  current_password: string
  password: string
  password_confirmation: string
}

/** Success body of POST /auth/change-password. Same shape as GET /auth/me. */
export type ChangePasswordResponse = User

export type UpdateProfileBody = {
  name_en?: string
  name_ar?: string | null
  phone?: string | null
  email?: string
  branch?: Branch | null
}

export type Place = {
  id: string
  name_en: string
  name_ar: string
  latitude: number | null
  longitude: number | null
  address: string | null
  is_headquarters: boolean
  is_active: boolean
  created_at: string | null
}

export type PlaceSnapshot = {
  place_id: string | null
  name: string
  lat: number | null
  lng: number | null
  address: string | null
}

export type DriverTotals = {
  trips: number
  total_seconds: number
  total_km: number
}

export type DriverSummary = {
  id: string
  name_en: string
  name_ar: string | null
  email: string
  role: 'driver'
  is_active: boolean
  phone: string | null
  is_available: boolean
  favorite_place_ids: string[]
  deleted_at: string | null
  deleted_by: string | null
  /** Present on GET /drivers and GET /drivers/{id}. */
  trips_this_week?: number
  totals?: DriverTotals
}

export type Driver = DriverSummary & {
  national_id: string
  car_license: string
  personal_license: string
}

export type DriverStatsBucket = {
  label: string
  from: string | null
  to: string | null
  trips: number
  total_seconds: number
  total_km: number
}

export type DriverStats = {
  period: string
  from: string | null
  to: string | null
  trips: number
  total_seconds: number
  total_km: number
  breakdown: DriverStatsBucket[]
}

export type DriverCompletedTrip = {
  id: string
  scheduled_at: string
  going_started_at: string | null
  finished_at: string | null
  pickup_summary: string | null
  destination_summary: string | null
  duration_seconds: number | null
  distance_km: number | null
  confirmation_status: TripConfirmationStatus | null
  driver_showed_up: boolean | null
}

export type Employee = {
  id: string
  name_en: string
  name_ar: string | null
  email: string
  role: 'employee'
  is_active: boolean
  phone: string | null
  branch: Branch | null
  deleted_at: string | null
  deleted_by: string | null
}

export type LinkedTrip = {
  id: string
  status: TripStatus
  driver_name_en: string | null
  driver_name_ar: string | null
  confirmation_status: TripConfirmationStatus | null
  driver_showed_up: boolean | null
}

export type RequestTrackingStage =
  | 'submitted'
  | 'approved'
  | 'rejected'
  | 'driver_assigned'
  | 'in_progress'
  | 'finished'
  | 'awaiting_confirmation'
  | 'confirmed'
  | 'unconfirmed'
  | 'cancelled'

export type RequestTrackingEvent = {
  stage: RequestTrackingStage
  reached_at: string | null
  actor_role: UserRole | null
}

export type RequestTrackingDriver = {
  name_en: string | null
  name_ar: string | null
  phone: string | null
}

export type RequestTracking = {
  stage: RequestTrackingStage
  timeline: RequestTrackingEvent[]
  rejection_reason: string | null
  driver: RequestTrackingDriver | null
  scheduled_at: string | null
  vehicle: { car_license: string } | null
}

export type TripRequest = {
  id: string
  employee_id: string
  employee_name_en: string | null
  employee_name_ar: string | null
  employee_phone: string | null
  employee_branch: string | null
  requester_role: UserRole
  pickup: PlaceSnapshot
  destination: PlaceSnapshot
  requested_at: string
  notes: string
  status: TripRequestStatus
  trip_id: string | null
  trip_status: TripStatus | null
  rejection_reason: string | null
  handled_by: string | null
  handled_at: string | null
  auto_approved: boolean
  suggested_group_id: string | null
  created_at: string
  trip: LinkedTrip | null
  tracking: RequestTracking | null
}

export type TripListBucket = 'all' | 'active' | 'completed' | 'cancelled'

export type TripListPeriod = 'day' | 'week' | 'month' | 'custom'

export type GroupSuggestionMember = {
  request_id: string
  requester_name_en: string | null
  requester_name_ar: string | null
  branch: string | null
  from_place: string
  to_place: string
  requested_at: string
}

export type GroupSuggestion = {
  cluster_id: string
  request_ids: string[]
  destination_label: string
  route_label: string
  date: string
  earliest_requested_at: string
  latest_requested_at: string
  members: GroupSuggestionMember[]
}

export type TripPassenger = {
  employee_id: string
  name_en: string | null
  name_ar: string | null
  phone: string | null
  branch: string | null
  request_id: string
  pickup: PlaceSnapshot
  destination: PlaceSnapshot
}

export type TripSummary = {
  id: string
  driver_id: string | null
  driver: DriverSummary | null
  scheduled_at: string
  status: TripStatus
  created_by: string
  pickup_summary: string | null
  destination_summary: string | null
  going_started_at: string | null
  going_ended_at: string | null
  return_started_at: string | null
  finished_at: string | null
  going_distance_m: number | null
  return_distance_m: number | null
  total_distance_m: number | null
  confirmation_status: TripConfirmationStatus | null
  confirmation_requested_at: string | null
  confirmed_at: string | null
  driver_showed_up: boolean | null
  confirmation_note: string | null
  passengers: TripPassenger[]
  passengers_branches: string[]
  created_at: string
  tracking: RequestTracking | null
}

export type Trip = TripSummary & {
  start_lat: number | null
  start_lng: number | null
  going_route: string | null
  return_route: string | null
}

export type DrivenRoutePoint = {
  lat: number
  lng: number
  recorded_at: string
}

export type TripReport = {
  status: TripStatus
  is_in_progress: boolean
  start: string | null
  finish: string | null
  going_duration_seconds: number | null
  waiting_duration_seconds: number | null
  return_duration_seconds: number | null
  total_duration_seconds: number | null
  going_distance_km: number | null
  return_distance_km: number | null
  total_distance_km: number | null
  going_route: string | null
  return_route: string | null
  driven_route: DrivenRoutePoint[]
}

export type DriverRecommendation = {
  driver: DriverSummary
  tier: number
  has_favorite_match: boolean
  has_conflict: boolean
  is_on_active_trip: boolean
  is_unavailable: boolean
  needs_confirmation: boolean
  trips_this_week: number
}

export type AvailabilityRequest = {
  id: string
  driver_id: string
  driver: DriverSummary | null
  requested_status: AvailabilityRequestStatus
  state: AvailabilityRequestState
  requested_at: string | null
  lat: number | null
  lng: number | null
  accuracy: number | null
  position_timestamp: string | null
  is_mocked: boolean | null
  distance_from_hq_m: number | null
  hq_place_id: string | null
  distance_band: HqDistanceBand
  reviewed_by: string | null
  reviewed_at: string | null
  rejection_reason: string | null
  reason: string | null
}

export type LiveMapTrip = {
  id: string
  status: TripStatus
  pickup_summary: string | null
  destination_summary: string | null
  scheduled_at: string
  going_started_at: string | null
}

export type AdminDashboard = {
  drivers: { total: number; checked_in: number; checked_out: number; absent: number }
  employees_total: number
  places_total: number
  trips: {
    unassigned: number
    assigned: number
    in_progress: number
    completed_today: number
    completed_this_week: number
  }
  requests: { pending: number; approved: number; rejected: number }
  unconfirmed_trips: number
}

/** GET /admin/dashboard wraps one object: `{ data: AdminDashboard }`, not a list. */
export type AdminDashboardResponse = {
  data: AdminDashboard
}

/**
 * GET /my-trips. drivers_admin and the assigned driver receive Trip.
 * admin, company_admin, and employee receive TripSummary.
 */
export type MyTripsResponse = Paginated<TripSummary | Trip>

export type LiveMapDriver = {
  driver: DriverSummary
  is_available: boolean
  state: LiveMapState
  trip: LiveMapTrip | null
  lat: number | null
  lng: number | null
  heading: number | null
  speed: number | null
  accuracy: number | null
  updated_at: string | null
  last_seen_at: string | null
  is_stale: boolean
  is_tracking: boolean
}
