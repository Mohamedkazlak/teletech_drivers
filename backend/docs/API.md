# TeleTech Drivers API contract

Base URL: `/api`  
Auth: `Authorization: Bearer {token}` (Sanctum personal access token)  
Error shape: `{ "message": "...", "errors": { "field": ["..."] } }` — `errors` only on `422`.

Roles: `admin`, `company_admin`, `drivers_admin`, `driver`, `employee`.

---

## Auth

### `POST /api/auth/register`

| | |
|---|---|
| **Roles** | Public |
| **Body** | `name_en`, `name_ar?`, `email`, `password`, `phone?`, `branch?` (`headquarters` \| `villa`) |
| **Success** | `201` — `{ "token": "...", "token_type": "Bearer", "user": { ... } }` (`user` includes `is_available`) |
| **Errors** | `422` validation (duplicate email, weak password) |

Always creates `role=employee`.

### `POST /api/auth/login`

| | |
|---|---|
| **Roles** | Public |
| **Body** | `email`, `password` |
| **Success** | `200` — `{ "token", "token_type", "user" }` (`user` includes `is_available`) |
| **Errors** | `401` invalid credentials / inactive / soft-deleted |

### `POST /api/auth/logout`

| | |
|---|---|
| **Roles** | Any authenticated active user |
| **Success** | `200` — `{ "message": "Logged out successfully." }` |
| **Errors** | `401` |

### `GET /api/auth/me`

| | |
|---|---|
| **Roles** | Any authenticated active user |
| **Success** | `200` — user object (no password). Drivers include `is_available` (open check-in today and no active trip) |
| **Errors** | `401` |

### `PATCH /api/auth/me`

| | |
|---|---|
| **Roles** | Any authenticated active user |
| **Body** | `name_en`, `name_ar?`, `phone?`, `email?`. `branch` is accepted at registration and on this endpoint only for `admin`. Any other role that sends `branch` gets `422` and the stored branch is unchanged. |
| **Success** | `200` — user object |
| **Errors** | `401`, `422` |

### `POST /api/auth/change-password`

| | |
|---|---|
| **Roles** | Any authenticated active user |
| **Body** | `current_password`, `password`, `password_confirmation` |
| **Success** | `200` — `{ "message": "Password changed successfully." }` |
| **Errors** | `401` unauthenticated or inactive; `422` wrong `current_password`, weak `password`, or confirmation mismatch; `429` when the auth limiter is exceeded |
| **Throttle** | `auth` limiter: **5 requests/minute/IP** (same as login and register) |

`password` uses the same rules as registration (`Password::defaults()`, minimum 8) and must match `password_confirmation`. A wrong `current_password` is `422` on that field and does not change the password. On success the new hash is stored and every **other** personal access token for that user is revoked; the token used for this request stays valid.

### `GET /api/auth/me/driver-profile`

| | |
|---|---|
| **Roles** | `driver` only |
| **Success** | `200` — full driver (includes `national_id`, `car_license`, `personal_license`, `favorite_place_ids`) |
| **Errors** | `401`, `403` (non-driver), `404` (no driver profile) |

---

## Places

### `GET /api/places`

| | |
|---|---|
| **Roles** | Any authenticated active user |
| **Query** | `is_active?`, `is_headquarters?`, `search?` (name_en/name_ar), `page?`, `per_page?` |
| **Success** | `200` — `{ "data": [ place ], "meta": { current_page, per_page, total, last_page } }` |
| **Errors** | `401` |

### `GET /api/places/{id}`

| | |
|---|---|
| **Roles** | Any authenticated active user |
| **Success** | `200` — place |
| **Errors** | `401`, `404` |

### `POST /api/places`

| | |
|---|---|
| **Roles** | `admin`, `company_admin`, `drivers_admin` |
| **Body** | `name_en`, `name_ar`, `latitude?`, `longitude?`, `address?`, `is_headquarters?`, `is_active?` |
| **Success** | `201` — place |
| **Errors** | `401`, `403`, `422` (coords must be both set or both null; second active HQ) |

### `PATCH /api/places/{id}`

| | |
|---|---|
| **Roles** | `admin`, `company_admin`, `drivers_admin` |
| **Body** | `name_en`, `name_ar`, `latitude?`, `longitude?`, `address?`, `is_headquarters`, `is_active` |
| **Success** | `200` — place |
| **Errors** | `401`, `403`, `404`, `422` |

No delete endpoint. Deactivate with `is_active=false`. Deactivating HQ is allowed. A second **active** headquarters is **rejected** with `422` (not atomically replaced). `created_at` is ISO-8601 UTC or `null`.

Place example:

```json
{
  "id": "uuid",
  "name_en": "TeleTech Headquarters",
  "name_ar": "المقر الرئيسي",
  "latitude": 30.0444,
  "longitude": 31.2357,
  "address": "Cairo, Egypt",
  "is_headquarters": true,
  "is_active": true,
  "created_at": "2026-11-03T08:00:00+00:00"
}
```

---

## Drivers

### `GET /api/drivers`

| | |
|---|---|
| **Roles** | `admin`, `drivers_admin`, `company_admin` |
| **Query** | `is_active?`, `attendance?` (`checked_in` \| `not_checked_in`), `search?`, `include_deleted?` (admin only), `page?`, `per_page?` |
| **Success** | `200` — paginated drivers. Full private fields for admin/drivers_admin; summary (no `national_id` / `car_license` / `personal_license`) for `company_admin`. Both shapes include `is_available`, `distance_from_hq_m` (today's check-in distance, or `null`), and `trips_this_week`. |
| **Errors** | `401`, `403` |

### `POST /api/drivers`

| | |
|---|---|
| **Roles** | `admin`, `drivers_admin` |
| **Body** | `name_en`, `name_ar`, `email`, `password`, `phone?`, `national_id`, `car_license`, `personal_license`, `favorite_place_ids[]` |
| **Success** | `201` — full driver |
| **Errors** | `401`, `403`, `422` (duplicate email, inactive/missing favorite places) |

Creates `users` + `driver_profiles` + favorites in one DB transaction.

### `GET /api/drivers/{id}`

| | |
|---|---|
| **Roles** | `admin`, `drivers_admin`, `company_admin` |
| **Success** | `200` — full or summary per role (via policy), including `trips_this_week` |
| **Errors** | `401`, `403`, `404` |

### `PATCH /api/drivers/{id}`

| | |
|---|---|
| **Roles** | `admin`, `drivers_admin` (not self) |
| **Body** | `name_en`, `name_ar`, `phone?`, `national_id`, `car_license`, `personal_license`, `favorite_place_ids[]`, `is_active`, `password?` |
| **Success** | `200` — driver (email/role immutable) |
| **Errors** | `401`, `403`, `404`, `422` |

### `DELETE /api/drivers/{id}`

| | |
|---|---|
| **Roles** | `admin`, `drivers_admin` (not self) |
| **Success** | `200` — soft-deleted driver (`is_active=false`, `deleted_at`, `deleted_by`). All tokens revoked. |
| **Errors** | `401`, `403`, `404` |

### `POST /api/drivers/{id}/restore`

| | |
|---|---|
| **Roles** | `admin`, `drivers_admin` (not self) |
| **Success** | `200` — reactivated driver |
| **Errors** | `401`, `403`, `404` |

Full driver example:

```json
{
  "id": "uuid",
  "name_en": "Driver One",
  "name_ar": "سائق",
  "email": "driver@example.com",
  "role": "driver",
  "is_active": true,
  "phone": "0100",
  "is_available": false,
  "distance_from_hq_m": null,
  "national_id": "...",
  "car_license": "...",
  "personal_license": "...",
  "favorite_place_ids": ["uuid"],
  "deleted_at": null,
  "deleted_by": null,
  "trips_this_week": 0
}
```

`trips_this_week` is on list and show. It counts non-cancelled trips whose `scheduled_at` falls in the current Saturday-start week in `Africa/Cairo`, the same week as driver recommendations. The list uses one grouped query. Create, update, delete, and restore omit it.

---

## Employees

### `GET /api/employees`

| | |
|---|---|
| **Roles** | `admin`, `company_admin` |
| **Query** | `is_active?`, `branch?`, `search?`, `include_deleted?` (admin only), `page?`, `per_page?` |
| **Success** | `200` — paginated employees |
| **Errors** | `401`, `403` |

### `POST /api/employees`

| | |
|---|---|
| **Roles** | `admin` |
| **Body** | `name_en`, `name_ar`, `email`, `password`, `phone?`, `branch?` |
| **Success** | `201` — employee |
| **Errors** | `401`, `403`, `422` |

### `GET /api/employees/{id}`

| | |
|---|---|
| **Roles** | `admin`, `company_admin` |
| **Success** | `200` — employee |
| **Errors** | `401`, `403`, `404` |

### `PATCH /api/employees/{id}`

| | |
|---|---|
| **Roles** | `admin` (not self) |
| **Body** | `name_en`, `name_ar`, `phone?`, `branch?`, `is_active`, `password?` |
| **Success** | `200` — employee (email/role immutable) |
| **Errors** | `401`, `403`, `404`, `422` |

### `DELETE /api/employees/{id}`

| | |
|---|---|
| **Roles** | `admin` (not self) |
| **Success** | `200` — soft-deleted; tokens revoked |
| **Errors** | `401`, `403`, `404` |

### `POST /api/employees/{id}/restore`

| | |
|---|---|
| **Roles** | `admin` (not self) |
| **Success** | `200` — reactivated employee |
| **Errors** | `401`, `403`, `404` |

Employee example:

```json
{
  "id": "uuid",
  "name_en": "Employee One",
  "name_ar": "موظف",
  "email": "employee@example.com",
  "role": "employee",
  "is_active": true,
  "phone": "0100",
  "branch": "headquarters",
  "deleted_at": null,
  "deleted_by": null
}
```

---

## Conventions (trips / trip requests)

- All timestamps are stored and returned in **UTC ISO-8601** (`DATE_ATOM`).
- Business calendar day uses `APP_BUSINESS_TIMEZONE` (default `Africa/Cairo`). Grouping “same day” is evaluated in that timezone.
- `trip_requests.requested_at` = when the passenger needs the trip. `created_at` = submission time.
- Place snapshot: when `place_id` is sent, the server copies `name` (from place `name_en`), `lat`, `lng`, `address` from the place and **ignores** client snapshot fields. Custom pin: `name` + `lat` + `lng` required (`place_id` null); optional `address`.
- State conflicts (wrong status, already linked, already handled) return **`409 Conflict`** with `{ "message": "..." }`. Validation stays **`422`**.
- Paginated lists use `{ "data": [...], "meta": { current_page, per_page, total, last_page } }`.

---

## Trip requests

### `POST /api/trip-requests`

| | |
|---|---|
| **Roles** | `employee`, `company_admin`, `admin`, `drivers_admin` |
| **Body** | `pickup` (`place_id` **or** custom `name`+`lat`+`lng`+`address?`), `destination` (same), `requested_at` (future), `notes?` |
| **Success** | `201` — trip request |
| **Errors** | `401`, `403` (driver), `422` (validation, same pickup/destination, past `requested_at`, place without coords), `404` (unknown place) |

Role strategy (requester_role from auth user, never body):

| Role | status | auto_approved | side effect |
|---|---|---|---|
| employee | pending | false | — |
| company_admin | approved | true | sets handled_by/handled_at; no trip |
| admin | approved | true | sets handled_by/handled_at; no trip |
| drivers_admin | approved | true | sets handled_by/handled_at **and** creates one unassigned trip linked in the same transaction |

### `GET /api/trip-requests/mine`

| | |
|---|---|
| **Roles** | Any authenticated active user (own requests) |
| **Query** | `status?`, `date_from?`, `date_to?`, `page?`, `per_page?` |
| **Success** | `200` — paginated |
| **Errors** | `401` |

### `GET /api/trip-requests`

| | |
|---|---|
| **Roles** | `admin`, `company_admin`, `drivers_admin` (`driver` and `employee` get `403`) |
| **Query** | `status?`, `has_trip?`, `date_from?`, `date_to?`, `employee_id?`, `search?`, `page?`, `per_page?` |
| **Success** | `200` — paginated |
| **Errors** | `401`, `403` |

### `GET /api/trip-requests/{id}`

| | |
|---|---|
| **Roles** | Owner; `company_admin`; `drivers_admin`; `driver` **only if** the request’s trip is assigned to that driver |
| **Success** | `200` — trip request |
| **Errors** | `401`, `403`, `404` |

### `POST /api/trip-requests/{id}/cancel`

| | |
|---|---|
| **Roles** | Owner only |
| **Success** | `200` — cancelled request |
| **Errors** | `401`, `403`, `404`, `409` when status is not pending and not (approved with `trip_id` null) |

### `POST /api/trip-requests/{id}/approve`

| | |
|---|---|
| **Roles** | `company_admin` only |
| **Body** | (none; `suggested_group_id` is **not** accepted from client) |
| **Success** | `200` — approved; sets `handled_by`, `handled_at` |
| **Errors** | `401`, `403`, `404`, `409` if not pending |

### `POST /api/trip-requests/{id}/reject`

| | |
|---|---|
| **Roles** | `company_admin` only |
| **Body** | `rejection_reason?` (max 500) |
| **Success** | `200` — rejected; sets `handled_by`, `handled_at` |
| **Errors** | `401`, `403`, `404`, `409` if not pending, `422` |

### `POST /api/trip-requests/approve-group`

| | |
|---|---|
| **Roles** | `company_admin` only |
| **Body** | `request_ids[]` (min 2, distinct UUIDs) |
| **Success** | `200` — `{ "data": [ trip_request, ... ] }` all approved with one shared server-generated `suggested_group_id` |
| **Errors** | `401`, `403`, `404`, `409` if any id is not pending (nothing written), `422` |

### `GET /api/trip-requests/grouping-suggestions`

| | |
|---|---|
| **Roles** | `company_admin` (clusters **pending**), `drivers_admin` (clusters **approved** with `trip_id` null) |
| **Success** | `200` — `{ "data": [ { cluster_id, request_ids, destination_label, route_label, date, earliest_requested_at, latest_requested_at, members } ] }` (size ≥ 2 only). `members` is `{ request_id, requester_name_en, requester_name_ar, branch, from_place, to_place, requested_at }[]` in `requested_at` order. `request_ids` stays. |
| **Errors** | `401`, `403` |

Algorithm: same calendar day (`APP_BUSINESS_TIMEZONE`) AND same destination (equal `destination_place_id`, or both custom pins within 500 m Haversine); union-find; singletons excluded.

Trip request example:

```json
{
  "id": "uuid",
  "employee_id": "uuid",
  "requester_role": "employee",
  "pickup": { "place_id": "uuid", "name": "HQ", "lat": 30.0, "lng": 31.0, "address": null },
  "destination": { "place_id": null, "name": "Custom", "lat": 30.1, "lng": 31.1, "address": null },
  "requested_at": "2026-11-04T08:00:00+00:00",
  "notes": "",
  "status": "pending",
  "trip_id": null,
  "rejection_reason": null,
  "handled_by": null,
  "handled_at": null,
  "auto_approved": false,
  "suggested_group_id": null,
  "created_at": "2026-11-03T10:00:00+00:00"
}
```

---

## Trips

### `POST /api/trips/from-requests`

| | |
|---|---|
| **Roles** | `drivers_admin` only |
| **Body** | `mode` = `one_per_request` \| `grouped`; `request_ids[]`; `scheduled_at` required for `grouped` (ignored for `one_per_request`, each trip uses that request’s `requested_at`) |
| **Success** | `201` — `{ "data": [ trip, ... ] }` status `unassigned`, `created_by` = actor; each request gets `trip_id` |
| **Errors** | `401`, `403`, `404`, `409` if any request is not approved with `trip_id` null (**nothing written**), `422` |

### `GET /api/trips`

| | |
|---|---|
| **Roles** | `company_admin`, `drivers_admin`, `admin` |
| **Query** | `status?`, `stage?`, `lifecycle?` (`upcoming`\|`in_progress`\|`completed`\|`cancelled`), `branch?`, `driver_showed_up?`, `driver_id?`, `date_from?`, `date_to?`, `period?` (`day`\|`week`\|`month`\|`custom`), `finished_period?` (`day`\|`week`\|`month`\|`custom`), `date?`, `unconfirmed?` (`true`\|`false`\|`1`\|`0`), `page?`, `per_page?`. `lifecycle` is the company-admin trip status: upcoming = unassigned+assigned, in progress = going+at destination+returning, completed = every finished trip (including a pending report), cancelled = cancelled. `date_from`/`date_to` win over `period` (`scheduled_at`). `finished_period` filters `finished_at` with the same Africa/Cairo Saturday-week helper and combines with the other filters. `custom` adds no window. `date` is the anchor for both periods. `unconfirmed=true` is the admin dashboard's unconfirmed set (auto-completed after 24h with no employee report). Invalid `finished_period`, `unconfirmed`, or `lifecycle` is `422`. |
| **Success** | `200` — paginated. Sensitive fields (`going_route`, `return_route`, `start_lat`, `start_lng`) only for `drivers_admin`. Trip objects also include `requester`, `requesters`, and `passenger_count` (see `GET /api/trips/{id}`). |
| **Errors** | `401`, `403`, `422` |

### `GET /api/my-trips`

| | |
|---|---|
| **Roles** | every active role |
| **Query** | Same as `GET /api/trips`, plus `bucket?` (`all`\|`active`\|`completed`\|`cancelled`). `finished_period` and `unconfirmed` apply inside the caller's scope. |
| **Success** | `200` — paginated. `driver`: assigned trips. `drivers_admin`: trips they created. `admin`, `company_admin`, `employee`: trips linked to a request they filed. |
| **Errors** | `401`, `422` |

### `GET /api/trips/mine`

| | |
|---|---|
| **Roles** | `driver` only (own trips) |
| **Query** | `status?`, `period?` (`week`\|`month`\|`year`), `date?`, `page?`, `per_page?` |
| **Success** | `200` — paginated full trip resources. Each trip includes `requester`, `requesters`, and `passenger_count` (see `GET /api/trips/{id}`). |
| **Errors** | `401`, `403` |

### `GET /api/trips/{id}`

| | |
|---|---|
| **Roles** | `drivers_admin` (full); assigned `driver` (full, own only); `company_admin` / `admin` (**summary** without `going_route`, `return_route`, `start_lat`, `start_lng`) |
| **Success** | `200` — trip + `passengers` derived from linked trip_requests + optional `driver` summary. `requester` is the first linked `trip_requests.employee_id` (`id`, `name_en`, `name_ar`, `phone`, `branch`) or `null`. `requesters` is one of those objects per linked request (grouped trips included). `passenger_count` is the sum of passenger rows across every request on the trip. Email, national id, and fellow-passenger phones from notes are not included. |
| **Errors** | `401`, `403`, `404` |

### `POST /api/trips/{id}/assign`

| | |
|---|---|
| **Roles** | `drivers_admin` only |
| **Body** | `driver_id` (must be role `driver`, active, not soft-deleted) |
| **Success** | `200` — `unassigned`→`assigned`, or reassign while already `assigned` (status stays `assigned`) |
| **Errors** | `401`, `403`, `404`, `409` invalid transition (e.g. status `going` or later), `422` invalid driver |

### `POST /api/trips/{id}/cancel`

| | |
|---|---|
| **Roles** | `drivers_admin` only |
| **Success** | `200` — cancelled from `unassigned` or `assigned` only |
| **Errors** | `401`, `403`, `404`, `409` otherwise |

**Cancel + linked requests:** mirrors Flutter — only the trip status becomes `cancelled`. Linked `trip_requests` keep their `trip_id` and status unchanged.

Trip summary (no sensitive fields) omits `going_route`, `return_route`, `start_lat`, `start_lng`. Full trip includes them.

### `POST /api/trips/{id}/start`

| | |
|---|---|
| **Roles** | Assigned `driver` only (own trip) |
| **Body** | `start_lat`, `start_lng` |
| **Success** | `200` — `assigned`→`going`; sets server `going_started_at`, `start_lat`/`start_lng` |
| **Errors** | `401`, `403` (other driver's trip / wrong role), `404`, `409` invalid transition, `422` |

### `POST /api/trips/{id}/arrive`

| | |
|---|---|
| **Roles** | Assigned `driver` only (own trip) |
| **Body** | `going_distance_m` (≥ 0), `going_route` (encoded polyline string; charset ASCII 63–126; max `polyline_max_length`) |
| **Success** | `200` — `going`→`at_destination`; sets server `going_ended_at`, distance + route |
| **Errors** | `401`, `403`, `404`, `409`, `422` |

### `POST /api/trips/{id}/start-return`

| | |
|---|---|
| **Roles** | Assigned `driver` only (own trip) |
| **Body** | none |
| **Success** | `200` — `at_destination`→`returning`; sets server `return_started_at` |
| **Errors** | `401`, `403`, `404`, `409` |

### `POST /api/trips/{id}/end`

| | |
|---|---|
| **Roles** | Assigned `driver` only (own trip) |
| **Body** | `return_distance_m` (≥ 0), `return_route` (encoded polyline; `""` is valid when no return points were recorded). Coordinates are not required. Phase must be `returning`. |
| **Success** | `200` — `returning`→`completed`; sets server `finished_at`, return distance/route, and **`total_distance_m = stored going_distance_m + return_distance_m`** (server-computed; client-sent timestamps ignored). Sets `confirmation_status` to `pending` (employee confirmation). Availability is not stored on the trip: ending the trip makes the driver available again only when today's attendance is still open. |
| **Failure body** | `409` `{ "message": "Trip status cannot transition from {from} to completed." }` when the phase is not `returning`. `422` `{ "message": "The given data was invalid.", "errors": { "return_route": ["..."] } }` when the route is missing or not a polyline. |
| **Errors** | `401`, `403`, `404`, `409`, `422` |

### `GET /api/trips/{id}/report`

| | |
|---|---|
| **Roles** | `admin`, `drivers_admin`, and `company_admin` (any trip `GET /trips` lists); assigned `driver` (own trip). `employee` is 403. Another driver's trip is 404. |
| **Success** | `200` — report object (partial trips return nulls for unreached fields; never fails). `driven_route` is `[]` because location history is not stored. |
| **Errors** | `401`, `403`, `404` |

Example:

```json
{
  "status": "completed",
  "is_in_progress": false,
  "start": "2026-11-03T08:00:00+00:00",
  "finish": "2026-11-03T10:00:00+00:00",
  "going_duration_seconds": 3600,
  "waiting_duration_seconds": 600,
  "return_duration_seconds": 3000,
  "total_duration_seconds": 7200,
  "going_distance_km": 12.5,
  "return_distance_km": 11.0,
  "total_distance_km": 23.5,
  "going_route": "_p~iF~ps|U_ulLnnqC_mqNvxq`@",
  "return_route": "_ulLnnqC_mqNvxq`@",
  "driven_route": []
}
```

### `GET /api/trips/{id}/driver-recommendations`

| | |
|---|---|
| **Roles** | `drivers_admin` only |
| **Success** | `200` — `{ "data": [ { driver, tier, has_favorite_match, has_conflict, is_on_active_trip, is_unavailable, needs_confirmation, trips_this_week } ] }` for **unassigned** or **assigned** trips |
| **Errors** | `401`, `403`, `404`, `409` if trip status is not unassigned/assigned |

Ranking: tier 0 = available + no schedule conflict + favorite match; tier 1 = available + no schedule conflict; tier 2 = else. Available means checked in today, not checked out, and no trip in `going`, `at_destination`, or `returning`. An active trip is tier 2. Tie-break: fewer non-cancelled trips this Saturday-start week (`Africa/Cairo`), then today's check-in distance from headquarters (nulls last, closer first), then `name_en`. `is_on_active_trip` is true for `going`, `at_destination`, or `returning`. `has_conflict` = schedule window or in-progress trip. `needs_confirmation` = unavailable or on an active trip or a schedule conflict.

---

## Attendance

Scan and own history: active `driver`. List, today's summary, QR, adjust, and another driver's history: active `admin` or `drivers_admin`.

The QR payload is `telecars-attendance:v{version}:{hmac_sha256}`. A scan body is `{ qr_payload, lat, lng, accuracy_m, is_mocked }`. The server checks the signature, then rejects `is_mocked`, then accuracy above `ATTENDANCE_MAX_ACCURACY_M`, then haversine distance beyond `ATTENDANCE_RADIUS_M`, then the business rule. Error JSON is `{ message, code }` and, for `outside_radius`, `distance_m` and `radius_m`.

| Method | Path | Roles | Success |
|---|---|---|---|
| POST | `/api/attendance/check-in` | driver | `201` attendance row. `409` `already_checked_in` |
| POST | `/api/attendance/check-out` | driver | `200`. `409` `not_checked_in`, `already_checked_out`, or `active_trip` |
| GET | `/api/attendance/today` | driver | `{ work_date, status, attendance }` |
| GET | `/api/attendance/me` | driver | `{ data, totals, meta }` including computed absent days |
| GET | `/api/attendance` | admin, drivers_admin | same history shape. Filters: `date`, `driver_id`, `period`, `status` |
| GET | `/api/attendance/today/summary` | admin, drivers_admin | `{ data: { work_date, off_day, counts, present, checked_in, checked_out, absent } }` |
| GET | `/api/drivers/{id}/attendance` | admin, drivers_admin | history plus totals |
| GET | `/api/attendance/qr` | admin, drivers_admin | `{ payload, hq_name, version }` |
| POST | `/api/attendance/adjust` | admin, drivers_admin | `201` create or `200` edit. Body requires `reason` |

Scan `422` codes: `invalid_qr`, `mock_location`, `low_accuracy`, `outside_radius`. A missing check-out stays null. Absent days are computed for working days from `created_at` through today, skipping weekly off days. `is_available` is an open check-in today with no active trip. It is not a stored column.

---

## Live location / live map

### `PUT /api/driver-location`

| | |
|---|---|
| **Roles** | `driver` |
| **Body** | `lat`, `lng`, `heading`, `speed`, `accuracy`, `is_tracking`, `trip_id?` (nullable; if set must be this driver's in-progress trip) |
| **Success** | `200` — upserts the single `driver_locations` row for the driver |
| **Errors** | `401`, `403`, `404` (trip_id not found), `422` accuracy over limit / invalid trip_id ownership-or-status, `429` throttle |
| **Throttle** | `driver-location` limiter: **12 requests/minute/user** (safe for an ~8 s heartbeat, a 20 m early send, and short bursts). Config: `teletech.driver_location_throttle_per_minute`. |

Accuracy: first publish (no row yet) allows up to `location_first_publish_accuracy_max_meters` (default 500); later publishes use `location_accuracy_max_meters` (default 50).

### `POST /api/driver-location/stop`

| | |
|---|---|
| **Roles** | `driver` |
| **Success** | `200` — sets `is_tracking=false` |
| **Errors** | `401`, `403`, `404` if no location row |

### `GET /api/live-map`

| | |
|---|---|
| **Roles** | `admin`, `drivers_admin` (`company_admin`, `employee`, `driver` → `403`). Same payload for both roles. |
| **Query** | `driver_id?`, `attendance?` (`checked_in` \| `not_checked_in`) |
| **Success** | `200` — `{ "data": [ { driver, trip: { id, status, pickup_summary, destination_summary, scheduled_at, going_started_at }, lat, lng, heading, speed, accuracy, updated_at, is_stale, is_tracking } ] }` for trips in `going` / `at_destination` / `returning` joined with `driver_locations` |
| **Errors** | `401`, `403` |

`is_stale` = `updated_at` older than `location_stale_seconds` (default 60), or missing location. Trip `scheduled_at` is ISO-8601 UTC. `going_started_at` is ISO-8601 UTC or `null`.

---

## Config thresholds (`config/teletech.php`)

| Key | Default | Meaning |
|---|---|---|
| `location_stale_seconds` | 60 | Live-map stale flag |
| `hq_near_meters` | 200 | HQ distance band near |
| `hq_medium_meters` | 1000 | HQ distance band medium |
| `schedule_conflict_window_hours` | 2 | Recommendation schedule conflict (± hours, inclusive) |
| `location_accuracy_max_meters` | 50 | Live location accuracy after first publish |
| `location_first_publish_accuracy_max_meters` | 500 | Live location accuracy on first upsert |
| `polyline_max_length` | 100000 | Max encoded route string length (safe for multi-hour 15 s tracks; under MySQL TEXT) |
| `driver_location_throttle_per_minute` | 12 | PUT `/api/driver-location` rate limit |

Attendance settings live in `config/attendance.php`: `ATTENDANCE_HQ_LAT`, `ATTENDANCE_HQ_LNG`, `ATTENDANCE_HQ_NAME`, `ATTENDANCE_RADIUS_M` (150), `ATTENDANCE_MAX_ACCURACY_M` (50), `ATTENDANCE_WEEKLY_OFF_DAYS` (5 = Friday), `ATTENDANCE_QR_SECRET` (derived from `APP_KEY` when empty), `ATTENDANCE_QR_VERSION` (1).

Env overrides use `TELETECH_*` prefixes (see config file).

---

## Polling guidance

- **Live map:** location events move markers immediately. The screen also polls about every **20 seconds** while it is open, in case the socket drops.
- **Attendance:** `attendance.checked_in`, `attendance.checked_out`, and `attendance.adjusted` refresh the attendance lists and the admin dashboard. The screens also poll while they are open.
