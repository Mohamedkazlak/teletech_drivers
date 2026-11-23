# TeleTech web API contract

Source of truth: `backend/routes/api.php`, the API controllers, FormRequests, Resources, policies, and `backend/bootstrap/app.php`. This document lists every endpoint the web app uses for **system admin** (`admin`), **company admin** (`company_admin`), and **drivers admin** (`drivers_admin`).

Base URL: `VITE_API_BASE_URL` (local default `http://127.0.0.1:8000/api`).

`driver` and `employee` can call `POST /auth/login`, but the web app must **not** keep their token. Show a clear message that the web console is only for admin, company admin, and drivers admin. Those roles use the mobile app.

## Conventions

- Auth header after login: `Authorization: Bearer {token}`. `token_type` is always `Bearer`.
- Send `Accept: application/json`. Send `Content-Type: application/json` when there is a body.
- `JsonResource::withoutWrapping()` is enabled. A single resource is the JSON object itself, **not** `{ "data": ... }`.
- Lists built with `PaginatedResourceResponse` use `{ "data": [...], "meta": { ... } }`.
- A few collection actions return `{ "data": [...] }` and **no** `meta` (called out per endpoint).
- Ids are UUID strings.
- Timestamps use ISO-8601 (`DATE_ATOM`), including `deleted_at`.
- Pagination defaults: `page=1`, `per_page=15`. `per_page` max is 100. `meta.last_page` is at least 1 even when `total` is 0.
- `period` is `week`, `month`, or `year` unless an endpoint says otherwise. Some endpoints also allow `all`. `date` is an anchor day (`YYYY-MM-DD`). Week starts Saturday. Boundaries use `Africa/Cairo`.
- Password rule is Laravel's unmodified `Password::defaults()`: minimum 8 characters. `confirmed` means the body must also include `password_confirmation`.
- Authenticated routes also run `EnsureUserIsActive` and `EnsurePasswordChangeNotRequired`.

While `must_change_password` is true, every authenticated route returns 403 `password_change_required` except:

- `POST /auth/change-password`
- `POST /auth/logout`
- `GET /auth/me`

`PATCH /auth/me` is **not** allowed until the password is changed.

### Shared shapes

```ts
type PageMeta = {
  current_page: number
  per_page: number
  last_page: number
  total: number
}

type User = {
  id: string
  name_en: string
  name_ar: string | null
  email: string
  role: 'admin' | 'company_admin' | 'drivers_admin' | 'driver' | 'employee'
  is_active: boolean
  phone: string | null
  branch: 'company_headquarters' | 'new_headquarters' | null
  must_change_password: boolean
  is_available: boolean
}

type PlaceSnapshot = {
  place_id: string | null
  name: string
  lat: number | null
  lng: number | null
  address: string | null
}
```

### Errors

| Status | When                                                                                         | Body                                                                                                                           |
| ------ | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| 401    | Missing/invalid token, inactive user, bad login                                              | `{ "message": "Unauthenticated." }` or `{ "message": "Invalid credentials." }` or `{ "message": "This account is inactive." }` |
| 403    | Policy denial                                                                                | `{ "message": "Forbidden." }`                                                                                                  |
| 403    | Password change still required                                                               | `{ "message": "You must change your password before continuing.", "code": "password_change_required" }`                        |
| 404    | Missing model or domain not-found                                                            | `{ "message": "Resource not found." }` or a specific message such as `"Trip not found."`                                       |
| 409    | State conflict or illegal trip transition                                                    | `{ "message": "<reason>" }` — no `errors` object                                                                               |
| 422    | Validation                                                                                   | `{ "message": "The given data was invalid.", "errors": { "<field>": ["<message>"] } }`                                         |
| 422    | Wrong current password                                                                       | `{ "message": "The given data was invalid.", "errors": { "current_password": ["The current password is incorrect."] } }`       |
| 422    | Domain rule (duplicate HQ, invalid favorite place, same pickup and destination, and similar) | `{ "message": "<reason>", "errors": { "general": ["<reason>"] } }`                                                             |
| 429    | Auth throttle (5 requests/minute/IP on login, register, change-password)                     | Laravel default `{ "message": "Too Many Attempts." }` plus `Retry-After`                                                       |

Boolean query values accept `true`, `false`, `1`, and `0` (any case for the words) on `is_active`, `has_trip`, `include_deleted`, `is_headquarters`, `awaiting_confirmation`, and `driver_showed_up`. Any other value is 422.

## Auth

### `POST /auth/login`

Public. Throttled.

Body: `{ "email": string, "password": string }`

200:

```json
{ "token": "string", "token_type": "Bearer", "user": User }
```

401 invalid credentials or inactive account. 422 validation.

Web behavior: if `user.role` is `driver` or `employee`, discard the token (call logout with it, then drop it) and do not start a session.

### `POST /auth/logout`

Auth. Allowed during forced password change.

Body: none.

200: `{ "message": "Logged out successfully." }`

### `POST /auth/change-password`

Auth. Allowed during forced password change. Throttled.

Body:

```json
{
  "current_password": "string",
  "password": "string (min 8)",
  "password_confirmation": "string"
}
```

200: `User` — the same shape as `GET /auth/me`. `must_change_password` is false.

422 on validation or a wrong current password.

### `GET /auth/me`

Auth. Allowed during forced password change.

200: `User`

### `PATCH /auth/me`

Auth. Blocked while a password change is required.

Partial body. Send only fields that should change. Present fields are required as follows:

| Field     | Rules                                               |
| --------- | --------------------------------------------------- |
| `name_en` | string, max 255, not empty if sent                  |
| `name_ar` | string or null, max 255                             |
| `phone`   | string or null, max 50                              |
| `email`   | email, max 255, unique except the current user      |
| `branch`  | `company_headquarters`, `new_headquarters`, or null |

200: `User`

### Not used by the web console

- `POST /auth/register` creates an **employee** only.
- `GET /auth/me/stats` and `GET /auth/me/driver-profile` are driver-only (403 for every web role).

## Places

Any signed-in user may list and read places. Create, update, and delete require `admin`, `company_admin`, or `drivers_admin`.

`Place`:

```ts
type Place = {
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
```

### `GET /places`

Query: `is_active` and `is_headquarters` (`true`/`false`/`1`/`0`), `search`, `page`, `per_page`.

200: `{ data: Place[], meta: PageMeta }`

### `GET /places/{id}`

200: `Place`. 404 if missing.

### `POST /places`

Body:

| Field                | Rules                                                      |
| -------------------- | ---------------------------------------------------------- |
| `name_en`, `name_ar` | required, string, max 255                                  |
| `latitude`           | optional number -90..90, required together with longitude  |
| `longitude`          | optional number -180..180, required together with latitude |
| `address`            | optional string, max 500                                   |
| `is_headquarters`    | optional boolean, default false                            |
| `is_active`          | optional boolean, default true                             |

201: `Place`

422 `errors.general` when a second **active** headquarters is created (`"Only one active headquarters place is allowed."`).

### `PATCH /places/{id}`

Partial. Send only the fields that should change. A full body still works. Sent string fields are required and non-empty. `is_headquarters` and `is_active` are booleans when sent. Coordinates stay a pair (`latitude` and `longitude` together).

200: `Place`. 404 if missing. 422 for a second active headquarters.

### `DELETE /places/{id}`

Soft-delete. 200: `Place` (the same shape as show). 422 `errors.general`: `"The headquarters place cannot be deleted."`

## Drivers

| Action                          | admin | company_admin     | drivers_admin |
| ------------------------------- | ----- | ----------------- | ------------- |
| List, show                      | yes   | yes, summary only | yes           |
| Create, update, delete, restore | yes   | no                | yes           |
| Stats, completed trips          | yes   | no                | yes           |

`company_admin` receives `DriverSummary` (no `national_id`, `car_license`, `personal_license`). The other two roles receive `Driver`.

`include_deleted=true` or `1` is admin only. Any other role that sends a truthy value gets 403. `false` / `0` and omitting the parameter list only non-deleted rows for every role that can list.

```ts
type DriverSummary = {
  id: string
  name_en: string
  name_ar: string | null
  email: string
  role: 'driver'
  is_active: boolean
  phone: string | null
  is_available: boolean
  distance_from_hq_m: number | null
  favorite_place_ids: string[]
  deleted_at: string | null
  deleted_by: string | null
  trips_this_week?: number
  totals?: { trips: number; total_seconds: number; total_km: number }
}

type Driver = DriverSummary & {
  national_id: string
  car_license: string
  personal_license: string
}
```

`totals` is included on **show** (all-time) and omitted on list. `trips_this_week` is included on list and show. It is the number of non-cancelled trips whose `scheduled_at` is in the current Saturday-start fleet week in `Africa/Cairo`, the same week as driver recommendations. The list computes it with one grouped query. Create, update, delete, restore, and nested `driver` objects omit it.

### `GET /drivers`

Query: `is_active` (`true`/`false`/`1`/`0`), `attendance` (`checked_in` \| `not_checked_in`), `search`, `include_deleted` (admin only; truthy values 403 for everyone else), `page`, `per_page`.

`attendance=checked_in` keeps drivers with an open check-in today (including a driver who is on a trip). `not_checked_in` is everyone else. `is_available` is stricter: open check-in today and no active trip (`going`, `at_destination`, `returning`). `distance_from_hq_m` is today's check-in distance, or `null`.

200: `{ data: Driver[] | DriverSummary[], meta }`

### `POST /drivers`

`admin`, `drivers_admin`. 201 `Driver`.

| Field                                            | Rules                                                           |
| ------------------------------------------------ | --------------------------------------------------------------- |
| `name_en`, `name_ar`                             | required, max 255                                               |
| `email`                                          | required, unique                                                |
| `password`                                       | required, min 8                                                 |
| `phone`                                          | nullable, max 50                                                |
| `national_id`, `car_license`, `personal_license` | required, max 100                                               |
| `favorite_place_ids`                             | required array (may be empty), max 5, each an active place UUID |

New drivers are created with `must_change_password: true` (visible on their own login, not on this resource).

422 `errors.general` when a favorite place is inactive or unknown.

### `GET /drivers/{id}`

200: `Driver` or `DriverSummary`, including `totals`. 404 if the id is not a driver.

### `GET /drivers/{id}/stats`

`admin`, `drivers_admin`.

Query: `period` **required** (`week` \| `month` \| `year` \| `all`), `date` optional.

200:

```ts
type DriverStats = {
  period: string
  from: string | null
  to: string | null
  trips: number
  total_seconds: number
  total_km: number
  breakdown: Array<{
    label: string
    from: string | null
    to: string | null
    trips: number
    total_seconds: number
    total_km: number
  }>
}
```

`from` / `to` are UTC ISO-8601. `period=all` has null bounds.

### `GET /drivers/{id}/trips`

`admin`, `drivers_admin`. Completed trips only.

Query: `period` (`week` \| `month` \| `year` \| `all`, optional), `date`, `page`, `per_page`.

200: `{ data: DriverCompletedTrip[], meta }`

```ts
type DriverCompletedTrip = {
  id: string
  scheduled_at: string
  going_started_at: string | null
  finished_at: string | null
  pickup_summary: string | null
  destination_summary: string | null
  duration_seconds: number | null
  distance_km: number | null
  confirmation_status: 'pending' | 'confirmed' | 'unconfirmed' | null
  driver_showed_up: boolean | null
}
```

### `PATCH /drivers/{id}`

Partial. Send only the fields that should change. A full body still works. Sent strings are required. `favorite_place_ids`, when sent, replaces the list (max 5, each an active place). Optional `password` (min 8) resets the password. A user cannot update themselves through this route.

200: `Driver`. 422 same favorite-place rule.

### `DELETE /drivers/{id}`

Soft-delete. 200: `Driver` with `deleted_at` set. Not a message envelope.

### `POST /drivers/{id}/restore`

200: `Driver` with `deleted_at: null`.

## Employees

| Action                          | admin | company_admin | drivers_admin |
| ------------------------------- | ----- | ------------- | ------------- |
| List, show                      | yes   | yes           | no            |
| Create, update, delete, restore | yes   | no            | no            |

`include_deleted=true` or `1` is admin only (403 for everyone else). `false` / `0` does not include deleted rows.

```ts
type Employee = {
  id: string
  name_en: string
  name_ar: string | null
  email: string
  role: 'employee'
  is_active: boolean
  phone: string | null
  branch: 'company_headquarters' | 'new_headquarters' | null
  deleted_at: string | null
  deleted_by: string | null
}
```

There is no `availability_status` and no `must_change_password` on this resource. Created employees do start with `must_change_password: true`.

### `GET /employees`

Query: `is_active` (`true`/`false`/`1`/`0`), `branch`, `search`, `include_deleted` (admin only; truthy values 403 for everyone else), `page`, `per_page`.

200: `{ data: Employee[], meta }`

### `POST /employees`

`admin`. 201 `Employee`.

Body: `name_en`, `name_ar`, `email`, `password` (min 8) required. `phone` nullable max 50. `branch` nullable enum.

### `GET /employees/{id}`

200 `Employee`. 404 if the id is not an employee.

### `PATCH /employees/{id}`

`admin`. Partial. Send only the fields that should change. A full body still works. Optional `password`. Cannot target yourself.

200: `Employee`

### `DELETE /employees/{id}`

`admin`. Soft-delete. 200: `Employee` (not a message).

### `POST /employees/{id}/restore`

`admin`. 200: `Employee`.

## Trip requests

```ts
type TripRequest = {
  id: string
  employee_id: string
  employee_name_en: string | null
  employee_name_ar: string | null
  employee_phone: string | null
  employee_branch: string | null
  requester_role: User['role']
  pickup: PlaceSnapshot
  destination: PlaceSnapshot
  requested_at: string
  notes: string
  status: 'pending' | 'approved' | 'rejected' | 'cancelled'
  trip_id: string | null
  trip_status: Trip['status'] | null
  rejection_reason: string | null
  handled_by: string | null
  handled_at: string | null
  auto_approved: boolean
  suggested_group_id: string | null
  created_at: string
  trip: {
    id: string
    status: Trip['status']
    driver_name_en: string | null
    driver_name_ar: string | null
    confirmation_status: 'pending' | 'confirmed' | 'unconfirmed' | null
    driver_showed_up: boolean | null
  } | null
}
```

`employee_branch` is the raw branch string or null (not re-validated on output).

### `POST /trip-requests`

`admin`, `company_admin`, `drivers_admin` (and employee). The caller becomes `employee_id`.

Body: `pickup` and `destination` objects. Each needs `place_id` **or** `name` + `lat` + `lng`, plus optional `address`. `requested_at` must be strictly after the current instant in `Africa/Cairo`. The same minute as now is rejected. `notes` optional, max 1000. Pickup and destination must differ.

201: `TripRequest`

422 `errors.general` for the same place or a place without coordinates.

A past `requested_at` is also 422. The message is on both fields:

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "requested_at": ["The scheduled time must be in the future."],
    "scheduled_at": ["The scheduled time must be in the future."]
  }
}
```

`Accept-Language: ar` returns `يجب أن يكون موعد الرحلة في المستقبل.` on those same fields. The comparison uses the instant, so a UTC offset on `requested_at` is honored.

### `GET /trip-requests/mine`

Any active user, including all three web roles. Returns requests **they filed**, not trips they manage.

Query: `status`, `bucket` (`active` \| `completed` \| `cancelled`), `awaiting_confirmation` (`true`/`false`/`1`/`0`), `date_from`, `date_to`, `page`, `per_page`.

200: `{ data: TripRequest[], meta }`

### `GET /trip-requests`

`admin`, `company_admin`, and `drivers_admin`. `driver` and `employee` are 403.

Query: `status`, `has_trip` (`true`/`false`/`1`/`0`), `branch`, `stage` (`needs_driver` \| `assigned`), `period` (`week` \| `month` \| `year`), `date` (anchor day used with `period`), `date_from`, `date_to`, `employee_id`, `search`, `page`, `per_page`.

`period` filters `requested_at` with the Saturday-start Africa/Cairo fleet week. It combines with `date_from` / `date_to` when both are sent.

For `drivers_admin`, `status` is **ignored** and forced to `approved`. `admin` and `company_admin` honor `status`.

200: `{ data: TripRequest[], meta }`

### `GET /trip-requests/grouping-suggestions`

`company_admin`, `drivers_admin`. No query params.

Company admin suggestions are built from **pending** requests. Drivers admin suggestions are built from **approved** requests that do not yet have a trip.

200: `{ data: GroupSuggestion[] }` — no `meta`.

```ts
type GroupSuggestionMember = {
  request_id: string
  requester_name_en: string | null
  requester_name_ar: string | null
  branch: string | null
  from_place: string
  to_place: string
  requested_at: string
}

type GroupSuggestion = {
  cluster_id: string
  request_ids: string[]
  destination_label: string
  route_label: string
  date: string
  earliest_requested_at: string
  latest_requested_at: string
  members: GroupSuggestionMember[]
}
```

`request_ids` is unchanged. `members` is the same requests in `requested_at` order, with the requester's names, branch, pickup name (`from_place`), and destination name (`to_place`). There is no dismiss endpoint and no query parameter.

### `GET /trip-requests/{id}`

200 `TripRequest` for the requester, `company_admin`, or `drivers_admin`. 403 for `admin` unless they are the requester.

### `POST /trip-requests/{id}/cancel`

Only the user who filed it (`employee_id`). 200 `TripRequest`. 409 on a bad state.

### `POST /trip-requests/{id}/approve`

`company_admin`. No body. 200 `TripRequest`. 409 on a bad state.

### `POST /trip-requests/{id}/reject`

`company_admin`.

Body: `{ "rejection_reason"?: string | null }` max 500.

200 `TripRequest`. 409 on a bad state.

### `POST /trip-requests/approve-group`

`company_admin`.

Body: `{ "request_ids": string[] }` minimum 2 distinct UUIDs.

200: `{ data: TripRequest[] }` — no `meta`. 409 on a bad state.

### `POST /trip-requests/{id}/confirm-trip`

Only the requester (mobile confirmation). Body: `{ "driver_showed_up": boolean, "note"?: string | null }` max 500.

Not a web-admin action unless that admin filed the request. 200 `TripRequest`. 409 on a bad state.

## Trips

`drivers_admin` (and the assigned driver) receive `Trip`, which adds `start_lat`, `start_lng`, `going_route`, `return_route`. `admin` and `company_admin` receive `TripSummary` without those fields.

```ts
type TripPassenger = {
  employee_id: string
  name_en: string | null
  name_ar: string | null
  phone: string | null
  branch: string | null
  request_id: string
  pickup: PlaceSnapshot
  destination: PlaceSnapshot
}

type TripSummary = {
  id: string
  driver_id: string | null
  driver: DriverSummary | null
  scheduled_at: string
  status:
    'unassigned' | 'assigned' | 'going' | 'at_destination' | 'returning' | 'completed' | 'cancelled'
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
  confirmation_status: 'pending' | 'confirmed' | 'unconfirmed' | null
  confirmation_requested_at: string | null
  confirmed_at: string | null
  driver_showed_up: boolean | null
  confirmation_note: string | null
  passengers: TripPassenger[]
  passengers_branches: string[]
  created_at: string
}

type Trip = TripSummary & {
  start_lat: number | null
  start_lng: number | null
  going_route: string | null
  return_route: string | null
}
```

`passengers_branches` is the unique non-empty passenger branches, sorted A–Z. The nested `driver` is always a summary (no license fields).

`stage` on list endpoints maps to statuses:

| stage             | statuses                         | confirmation             |
| ----------------- | -------------------------------- | ------------------------ |
| `unassigned`      | unassigned                       |                          |
| `assigned`        | assigned                         |                          |
| `in_progress`     | going, at_destination, returning |                          |
| `awaiting_report` | completed                        | pending                  |
| `completed`       | completed                        | confirmed or unconfirmed |
| `cancelled`       | cancelled                        |                          |

### `GET /trips`

`admin`, `company_admin`, `drivers_admin`.

Query: `status`, `stage`, `branch`, `driver_showed_up` (`true`/`false`/`1`/`0`), `driver_id`, `date_from`, `date_to`, `period` (`day` \| `week` \| `month` \| `custom`), `finished_period` (`day` \| `week` \| `month` \| `custom`), `date` (anchor day used with `period` and `finished_period`), `unconfirmed` (`true`/`false`/`1`/`0`), `page`, `per_page`.

`period` filters `scheduled_at` in `Africa/Cairo`. `day` is that calendar day. `week` starts Saturday. `month` is the calendar month. `custom` does not add a window. When `date_from` or `date_to` is also sent, those bounds are used and `period` is ignored. `date_from` / `date_to` still work on their own.

`finished_period` filters `finished_at` with that same helper and combines with the other filters, including `date_from` / `date_to` and `period`. `custom` does not add a `finished_at` window. An unknown value is 422.

`unconfirmed=true` returns the trips the admin dashboard counts as `unconfirmed_trips`: auto-completed after the 24h window with no employee report. `false` returns every other trip. An unknown value is 422.

200: `{ data: TripSummary[] | Trip[], meta }`

### `GET /trips/{id}`

Same roles. 200: `Trip` for `drivers_admin`, `TripSummary` for `admin` and `company_admin`.

### `GET /trips/created-by-me`

**`drivers_admin` only.** This is the drivers-admin "My Trips" list.

Query: `bucket` (`active` \| `completed` \| `cancelled`), `page`, `per_page`.

`active` = unassigned, assigned, going, at_destination, returning.

200: `{ data: Trip[], meta }`

### `POST /trips/from-requests`

`drivers_admin`.

Body:

```json
{
  "mode": "one_per_request" | "grouped",
  "request_ids": ["uuid"],
  "scheduled_at": "ISO-8601, required when mode is grouped"
}
```

`grouped` needs at least two ids. `one_per_request` needs at least one. `scheduled_at` is ignored for `one_per_request`.

`scheduled_at` for `grouped` must be strictly after now in `Africa/Cairo`. A past value is 422 `errors.scheduled_at` with `The scheduled time must be in the future.` (`يجب أن يكون موعد الرحلة في المستقبل.` when `Accept-Language` is Arabic). Nothing is written.

201: `{ data: Trip[] }` — no `meta`. 409 on a bad state. 422 for validation.

### `POST /trips/{id}/assign`

`drivers_admin`. Body: `{ "driver_id": uuid }`.

200: `Trip`. 422 `errors.general` when the driver is not an active driver. 409 on a bad state.

### `POST /trips/{id}/cancel`

`drivers_admin`. No body. 200 `Trip`. 409 on a bad state.

### `GET /trips/{id}/report`

`admin`, `drivers_admin`, `company_admin`, and the assigned `driver`. 200:

```ts
type DrivenRoutePoint = {
  lat: number
  lng: number
  recorded_at: string
}

type TripReport = {
  status: Trip['status']
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
```

`admin`, `drivers_admin`, and `company_admin` can read the report of any trip `GET /trips` returns. That list is not narrowed by company: there is one fleet, and a trip with no linked request is included. The assigned driver can read their own trip. `employee` and every other role are 403. A trip outside the caller's set (another driver's trip, or an id that does not exist) is 404 `Trip not found.` A malformed id is 404 `Resource not found.`

`driven_route` is ordered `{ lat, lng, recorded_at }`, downsampled to at most 500 points. The API stores only the driver's latest location (`driver_locations`, one row per driver), not a tracking history, so this array is empty. It is not derived from `going_route` or `return_route`.

### `GET /trips/{id}/driver-recommendations`

`drivers_admin`. No query. 200: `{ data: DriverRecommendation[] }` — no `meta`.

```ts
type DriverRecommendation = {
  driver: DriverSummary
  tier: number
  has_favorite_match: boolean
  has_conflict: boolean
  is_on_active_trip: boolean
  is_unavailable: boolean
  needs_confirmation: boolean
  trips_this_week: number
}
```

`trips_this_week` uses the Saturday-start fleet week in `Africa/Cairo`, the same week as `period=week`.

### `GET /my-trips`

Every active role. Same query and pagination as `GET /trips`, including `finished_period` and `unconfirmed`, plus `bucket` (`all` \| `active` \| `completed` \| `cancelled`, default `all`). The scope depends on the caller:

| Role | Rows |
| ---- | ---- |
| `driver` | Trips assigned to me |
| `drivers_admin` | Trips I created |
| `admin`, `company_admin`, `employee` | Trips linked to a request I filed |

`bucket` uses the same trip statuses as `GET /trip-requests/mine`: `active` is not completed and not cancelled, `completed` is completed, `cancelled` is cancelled. `all` and an omitted bucket do not filter. It combines with the other filters. An unknown bucket is 422.

200: `{ data: TripSummary[] \| Trip[], meta }`. `drivers_admin` and the assigned `driver` receive `Trip`. The other roles receive `TripSummary`.

`GET /trips/mine` (driver only) and `GET /trips/created-by-me` (drivers admin only) are unchanged.

### Not for web roles

`GET /trips/mine` is **driver only**. `admin` and `company_admin` receive 403 on that path. Use `GET /my-trips`.

`POST /trips/{id}/start`, `/arrive`, `/start-return`, and `/end` are the assigned driver only.

## Admin dashboard

### `GET /admin/dashboard`

`admin` only. Every other role is 403.

200:

```ts
type AdminDashboard = {
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
```

The body is `{ data: AdminDashboard }`.

Counts exclude soft-deleted drivers, employees, and places, and include inactive ones. `drivers.checked_in`, `drivers.checked_out`, and `drivers.absent` are today's attendance in `Africa/Cairo`. Friday (or the configured weekly off days) reports `absent: 0`. `trips.in_progress` is `going`, `at_destination`, and `returning`. Completed windows use `finished_at` in `Africa/Cairo`: today is the calendar day, and the week starts Saturday (exclusive end the next Saturday). `requests` does not include `cancelled`. `unconfirmed_trips` counts `confirmation_status = unconfirmed`.

## Attendance

One headquarters QR. The driver scans it to check in and scans it again to check out. The server accepts a scan only when the QR signature is valid and the reported position is inside the headquarters radius. A working day with no check-in is absent. Absent days are computed, not stored. The clock and the week are `Africa/Cairo`, Saturday through Friday. Configured weekly off days (default Friday) are not absent.

`is_available` is derived: an attendance row for today, `checked_out_at` null, and no trip in `going`, `at_destination`, or `returning`.

Scan and own history: active `driver`. List, summary, QR, adjust, and another driver's history: active `admin` or `drivers_admin`. `company_admin` and `employee` are 403.

```ts
type AttendanceDay = {
  driver_id: string
  driver_name_en: string | null
  driver_name_ar: string | null
  work_date: string
  status: 'checked_in' | 'checked_out' | 'absent'
  attendance_id: string | null
  checked_in_at: string | null
  checked_out_at: string | null
  on_site_hours: number | null
  check_in_distance_m: number | null
  source: 'scan' | 'admin' | null
  adjustment_reason: string | null
}
```

History responses are `{ data: AttendanceDay[], totals, meta }`. `totals` covers the whole filter, not only the current page: `{ days_present, days_absent, total_on_site_hours }`. On-site hours count only when both timestamps exist.

### `POST /attendance/check-in` and `POST /attendance/check-out`

Driver only. Body: `{ qr_payload, lat, lng, accuracy_m, is_mocked }`.

Validation order: QR signature, then `is_mocked` must be false, then accuracy at or under `ATTENDANCE_MAX_ACCURACY_M` (default 50), then haversine distance to headquarters at or under `ATTENDANCE_RADIUS_M` (default 150), then the business rule.

| Code | HTTP | When |
| --- | --- | --- |
| `invalid_qr` | 422 | Signature or version does not match |
| `mock_location` | 422 | `is_mocked` is true |
| `low_accuracy` | 422 | Accuracy is above the maximum |
| `outside_radius` | 422 | Distance is greater than the radius. Body also has `distance_m` and `radius_m` |
| `already_checked_in` | 409 | This work date already has a check-in |
| `not_checked_in` | 409 | Check-out with no check-in today |
| `already_checked_out` | 409 | Check-out already recorded |
| `active_trip` | 409 | Check-out while a trip is `going`, `at_destination`, or `returning` |

A second check-in on the same work date is `already_checked_in` even after check-out. A missing check-out stays null. Check-in also updates the driver's last known location.

### `GET /attendance/today`

Driver. `{ work_date, status: 'not_checked_in' | 'checked_in' | 'checked_out', attendance }`.

### `GET /attendance/me`

Driver. Query: `period` (`week` \| `month` \| `year`), optional `date` anchor, or `date_from` and `date_to`. Includes computed absent days from the driver's `created_at` through today, skipping weekly off days and future days.

### `GET /attendance`

`admin`, `drivers_admin`. Query: `date`, `driver_id`, `period`, `status` (`present` \| `absent` \| `checked_in` \| `checked_out`), `page`, `per_page`. `present` is any stored row.

### `GET /attendance/today/summary`

`admin`, `drivers_admin`. `{ data: { work_date, off_day, counts, present, checked_in, checked_out, absent } }`. Each list row uses `id` for the driver.

### `GET /drivers/{id}/attendance`

`admin`, `drivers_admin`. Same history shape and totals as `GET /attendance/me`.

### `GET /attendance/qr`

`admin`, `drivers_admin`. `{ payload, hq_name, version }`. The payload is `telecars-attendance:v{version}:{hmac}`. Raising `ATTENDANCE_QR_VERSION` invalidates printed codes.

### `POST /attendance/adjust`

`admin`, `drivers_admin`. Body: `{ driver_id, work_date, checked_in_at, checked_out_at?, reason }`. `reason` is required. Creates (201) or edits (200) the row with `source: admin`. `work_date` cannot be in the future, the check-in instant must fall on that Cairo date, and check-out cannot be before check-in (`future_date`, `work_date_mismatch`, `checkout_before_checkin`, all 422).

## Live map

### `GET /live-map`

`admin` and `drivers_admin`. `company_admin`, `employee`, and `driver` are 403. Both roles receive the same payload.

Query: `driver_id` (uuid), `attendance` (`checked_in` \| `not_checked_in`).

200: `{ data: LiveMapDriver[] }` — no `meta`. Not paginated.

```ts
type LiveMapDriver = {
  driver: DriverSummary
  is_available: boolean
  state: 'on_trip' | 'available' | 'unavailable'
  trip: {
    id: string
    status: Trip['status']
    pickup_summary: string | null
    destination_summary: string | null
    scheduled_at: string
    going_started_at: string | null
  } | null
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
```

`updated_at` and `last_seen_at` are the same value.

`PUT /driver-location` and `POST /driver-location/stop` are driver-only.

## Notifications

Any authenticated user. Each row belongs to that user. Another user's id is 403 on read, and a missing id is 404.

```ts
type Notification = {
  id: string
  type:
    | 'request_submitted'
    | 'trip_ready_to_assign'
    | 'trip_assigned'
    | 'own_trip_assigned'
    | 'trip_ended_report_needed'
  title_key: string
  body_key: string
  params: {
    requester_name_en?: string
    requester_name_ar?: string
    driver_name_en?: string
    driver_name_ar?: string
    pickup?: string
    destination?: string
  }
  title: string
  body: string
  trip_request_id: string | null
  trip_id: string | null
  read_at: string | null
  created_at: string
}
```

`title` and `body` are the server's rendering of `title_key` / `body_key` for the request locale. Clients should render the keys themselves so a language switch does not need a refetch. Placeholders are `requester`, `driver`, `pickup`, and `destination`. Use `*_ar` when the UI language is Arabic and that value is non-empty, otherwise `*_en`.

| `title_key` | Audience |
| --- | --- |
| `notifications.request_submitted.title` | Company admins, except the actor |
| `notifications.trip_ready_to_assign.title` | Drivers admins, except the actor |
| `notifications.trip_assigned.title` | The assigned driver, and a requester who is not a company or drivers admin |
| `notifications.own_trip_assigned.title` | The company or drivers admin who filed the request, including when they assign the driver |
| `notifications.trip_ended_report_needed.title` | The requester, when the trip ends |

### `GET /notifications`

Query: `unread` (`true`/`false`/`1`/`0`), `page`, `per_page` (max 100, default 15).

200: `{ data: Notification[], meta }`. Newest first.

### `GET /notifications/unread-count`

200: `{ "count": number }`

### `POST /notifications/{id}/read`

200: `Notification`. The first `read_at` is kept when the row is already read.

### `POST /notifications/read-all`

200: `{ "updated": number }`. Rows that already have `read_at` are left unchanged. Other users' rows are not touched.

## Resolved inconsistencies

1. **`GET /my-trips`** is the single "my trips" list for every role. `GET /trips/mine` and `GET /trips/created-by-me` still work.
2. **`GET /admin/dashboard`** is the system-admin summary. `GET /auth/me/stats` stays driver-only.
3. **`admin` can list trip requests** with the same filters as company admin, including `period`.
4. **Boolean queries** accept `true` / `false` / `1` / `0` on every flag listed above.
5. **Truthy `include_deleted`** is 403 unless the caller is `admin`.
6. **PATCH** on places, drivers, and employees validates only the fields that were sent. A full body still works.
7. **DELETE** on places, drivers, and employees returns 200 and the soft-deleted resource.
8. **`deleted_at`** uses `DATE_ATOM`, like every other timestamp.
9. **`trips_this_week`** uses the Saturday-start fleet week. Driver recommendations and `GET /drivers` share that week.
10. **`admin` can read `GET /live-map`.** The payload matches `drivers_admin`.
11. **`finished_period` and `unconfirmed`** filter `GET /trips` and `GET /my-trips`. `unconfirmed` is the dashboard's unconfirmed set.
12. **A malformed UUID** in `{id}` returns JSON 404 `{ "message": "Resource not found." }` instead of a database 500. That is the same body `findOrFail` uses for a missing driver or employee.
13. **Change-password success** returns the updated `User`.

## Remaining differences

- **Wrapping.** A single resource is the object itself. Paginated lists use `{ data, meta }`. Grouping suggestions, approve-group, create-trips, recommendations, live map, and `GET /admin/dashboard` use `{ data }` without `meta`.
- **`last_page` is 1 when `total` is 0.**
- **`drivers_admin` `GET /trip-requests` still forces `status=approved`.** `has_trip`, `stage`, and `period` still apply.
- **Company admin can list drivers and employees.** The driver payload is the summary. Stats and completed trips stay 403.
- **`employee_branch` and passenger `branch`** are plain strings, not guaranteed to be the `Branch` enum, and may be null.
- **A well-formed id that is missing** can still use a domain message such as `"Place not found."` or `"Trip not found."`. A malformed id does not reach that code and uses `"Resource not found."`
