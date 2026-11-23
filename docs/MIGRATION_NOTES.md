# Flutter → Laravel migration notes

The Flutter app talks only to the Laravel API. Daily attendance replaced the availability-request flow: drivers scan the headquarters QR, and a working day with no check-in is absent. The notes below describe earlier slices and still mention the old availability screens.

Permission rules now live in the Laravel policies and `backend/docs/API.md`. This note does not copy them.

## How to run against the API

### Emulator / simulator (debug defaults)

- **Android emulator:** `http://10.0.2.2:8000/api` (maps to host loopback)
- **iOS simulator:** `http://127.0.0.1:8000/api`

```bash
flutter run
# or explicitly:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

### Physical phone (same LAN as the laptop)

1. Start Laravel (`php artisan serve --host=0.0.0.0 --port=8000`).
2. Find the laptop LAN IP (e.g. `192.168.1.20`).
3. Run:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
```

Debug Android allows cleartext HTTP (`android/app/src/debug/AndroidManifest.xml`).
iOS debug allows local networking via `NSAllowsLocalNetworking`.
**Release builds require HTTPS** and must pass `--dart-define=API_BASE_URL=https://…/api`.

---

## Slice status

| Slice | Scope | Status |
|-------|--------|--------|
| **5A** | Auth/session, places, drivers, employees | **Done** |
| **5B** | Trip requests, trips | **Done** |
| **5C** | Availability, live location, live map; client database SDK removed | **Done** |
| **5D** | Glass bottom bar, profile, settings, Phase 4.1 fields | **Done** |

---

## Slice 5D navigation

Each role has one `StatefulShellRoute.indexedStack`. The floating bar is `GlassBottomBar` inside `RoleShell`. It does not know roles. Destinations come from `RoleNavigationConfig` only.

| Role | Bar | More |
|------|-----|------|
| Employee | My trips, Profile, Settings | — |
| Driver | Availability, Assigned trips, Completed trips, Stats | Profile, Settings |
| Company admin | Requested trips, My trips, Trips, Places | Profile, Settings |
| Drivers admin | Requests, Trips, Availability requests, Drivers | My trips, Live map, Profile, Settings |
| Admin | Dashboard, Drivers, Employees, Places | My trips, Profile, Settings |

Branch order is the bar items, then the More items. Tapping More calls `goBranch` on that branch, so the bar stays and the tab keeps its state. A pending availability count is a badge on Availability requests for drivers admin. Driver Completed trips, Driver Stats, and Company admin My trips are placeholders.

Detail, create, picker, and full-screen map routes use the root navigator (`parentNavigatorKey`), so the bar is not on those screens. `/complete-profile` stays outside every shell. After sign-in the first branch is still the role home.

To add a destination, edit `RoleNavigationConfig` for that role and add a matching `GoRoute` in `buildRoleShellRoutes`. Do not branch on role inside a widget.

The bar is one blurred pill (sigma about 20), 64 high, radius about 28, inset 16 horizontal and 12 plus the safe area. Light surfaces use about 55% opacity and dark about 45%. It hides while the keyboard is open. `GlassBarInset` is the bar's total height; root-tab lists with their own padding add it, and FABs in `AppScaffold` sit above it. The app theme is light only; the dark opacity is ready for a dark theme.

Language is stored in `shared_preferences` under `app_locale` (`LocaleStore`) and applied before the first frame.

## Polling vs one-shot fetch

| Provider | Strategy |
|----------|----------|
| `currentUserProvider` | Session stream from `ApiAuthRepository` (token + `GET /auth/me`); re-check on app resume. `refreshSession()` refetches `/auth/me` after availability mutations |
| `activePlacesProvider` / `allPlacesProvider` | **PollingStream** every 30s |
| `allDriversProvider` / `allDriverProfilesProvider` | **PollingStream** every 20s |
| `allEmployeesProvider` | **PollingStream** every 20s |
| `driverProfileProvider` / `employeeProvider` | One-shot `FutureProvider` (invalidate after mutations) |
| `employeeTripRequestsProvider` | **PollingStream** every 15s (`/trip-requests/mine`) |
| `pendingTripRequestsProvider` | **PollingStream** every 15s (`status=pending`) |
| `allTripRequestsProvider` | **PollingStream** every 15s (`/trip-requests`) |
| `approvedAwaitingTripRequestsProvider` | **PollingStream** every 15s (`status=approved&has_trip=0`) |
| `watchTripRequestByIdProvider` | One-shot stream (`GET /trip-requests/{id}`); invalidate after mutations |
| `tripRequestByIdProvider` / `tripRequestsByIdsProvider` | One-shot `FutureProvider`; invalidate after mutations |
| `pendingGroupingSuggestionsProvider` / `approvedGroupingSuggestionsProvider` | One-shot fetch via `GET /trip-requests/grouping-suggestions` (re-runs when list data changes) |
| `allTripsProvider` | **PollingStream** every 15s (`GET /trips`) |
| `driverTripsProvider` | **PollingStream** every 15s (`GET /trips/mine`, filtered by driver id) |
| `watchTripByIdProvider` | **PollingStream** every 15s while the screen is open |
| `tripByIdProvider` | One-shot `FutureProvider`; invalidate after mutations |
| `tripReportProvider` | One-shot `FutureProvider` (`GET /trips/{id}/report`); refetch when trip status changes |
| `driverRecommendationsProvider` | One-shot `FutureProvider` (`GET /trips/{id}/driver-recommendations`) |
| `pendingAvailabilityRequestsProvider` | **PollingStream** every 15s while the queue is open (`GET /availability-requests?state=pending`). Server FIFO order is kept |
| `driverLatestAvailabilityRequestProvider` | **PollingStream** every 15s while open (`GET /availability-requests/mine`, first row) |
| `reviewedAvailabilityRequestsProvider` | One-shot. Two filtered reads (`approved` and `rejected`), merged newest-first, cap 50. Invalidate after approve/reject |
| `driverAvailabilityMonthRequestsProvider` | One-shot (`driver_id`, `year`, `month`). Refetches when the selected month changes. Invalidate after approve/reject |
| `driverOfficialAvailabilityProvider` | Derived. Signed-in driver uses `currentUserProvider` (`users.availability_status`). Other viewers use `allDriversProvider`. No extra endpoint |
| `headquartersPlaceProvider` | Derived from `activePlacesProvider` (map pin only; distance is not computed on the client) |
| `adminLiveMapLocationsProvider` | **PollingStream** every 20s while the live map is open (`GET /live-map`, optional `driver_id`). Location broadcasts refresh it sooner. |

After approve / reject / cancel / assign / lifecycle / create-trips / create-request mutations, controllers call `invalidateTripRequestProviders` / `invalidateTripProviders`.

After submit / cancel / approve / reject of an availability request, controllers call `invalidateAvailabilityProviders` (queue, own request, reviewed list, month history, driver list, and `refreshSession()`).

---

## Logic that now lives on the server

| Concern | Client now | Server |
|---------|------------|--------|
| Create-request status / auto-approve / linked trip | Submits pickup, destination, requested time, notes | `CreateTripRequestStrategyFactory` |
| Grouping suggestions | Displays the response | `GET /trip-requests/grouping-suggestions` |
| Driver recommendations | Displays the response | `GET /trips/{id}/driver-recommendations` |
| Trip report durations / km | Decodes polylines for the map | `GET /trips/{id}/report` |
| Trip status transitions | Calls lifecycle endpoints | Server sets timestamps and totals |
| Sensitive trip fields | Does not send them | `TripSummaryResource` omits routes and start coordinates for company admin and admin |
| HQ distance, HQ place, distance band | Colors the band the server sends (`near` / `medium` / `far` / `unknown`) | Computed on submit |
| Replacing a pending availability request | Submits the new request only | Server replaces the previous pending row |
| Pending queue order | Shows the response order | FIFO (`requested_at` ascending) |
| Official availability | Reads `availability_status` | Updated only by approve |
| Availability while a trip is going or returning | Buttons can be disabled for instant feedback | `409` is authoritative |
| Who appears on the live map, and whether a fix is stale | Renders `is_stale` | `GET /live-map` (`is_stale` when `updated_at` is missing or older than 60s) |
| Location sample limits | Skips a `422` sample and waits out a `429` | Accuracy caps and 12 publishes per minute |

The client still rejects a mocked, inaccurate (`> 50 m`), or stale (`> 30 s`) availability fix before the request is sent. The server repeats those checks.

---

## Known limitations

- **Cancel trip leaves requests linked.** Cancelling a trip sets the trip status to `cancelled`. Linked trip requests keep their `trip_id`.
- **No push notifications.** Queues, the driver's own request, and the live map update by polling while the screen is open.
- **`availability_approved_by` is not on the user or driver resources.** `availability_updated_at` is mapped and the driver list shows "last approved" when it is present. Who approved is still not in the payload.
- **Recommendation ranking.** `is_on_active_trip` is shown as its own chip. It does not change tier. `isRecommended` stays `tier <= 1 && available && !has_conflict`. `needs_confirmation` is still true when the driver is on an active trip.

---

## Manual end-to-end checklist

Use a debug build pointed at the LAN or emulator API. Sign out between roles.

### Employee

1. Sign in. If branch or phone is missing, complete the profile and confirm home opens.
2. Create a trip request (pickup, destination, time). It appears on My requests without leaving the screen.
3. Open the request and confirm status changes after a company admin approves or rejects it (within about 15 seconds, or immediately after you pull back onto the list).
4. Confirm there is no availability queue and no drivers-admin live map in the navigation you can open.

### Driver

1. Sign in. The availability chip matches `availability_status` from the profile.
2. With a good GPS fix (about 50 m or better, a few seconds old, not a mock location), submit Available or Unavailable. A second submit replaces the pending request; you do not cancel the first one yourself.
3. Start an assigned trip (Going). Location sharing starts. Arrive pauses it. Returning starts it again. End trip stops sharing. The app does not show an error if stop finds no location row.
4. While the trip is Going or Returning, the availability buttons stay disabled. If a request is still sent, the message is the existing "finish your active trip" conflict text.
5. After Drivers Admin approves the request, leave and reopen the driver home (or wait for the profile refresh). The chip matches the approved status.

### Company admin

1. Sign in. Open the pending trip-request queue and approve one request and reject another.
2. Open places and confirm the headquarters place is visible.
3. Confirm the drivers-admin live map route is not available for this role.

### Drivers admin

1. Open the pending availability queue. Order is oldest first and the list refreshes about every 15 seconds while the screen stays open.
2. Approve one request. The driver's status chip on the drivers list updates. Reject another with a reason. Both leave the pending queue and show on the history tab after the refresh.
3. Open a driver's month history, approve or reject from the queue, return to that month, and confirm the row is there.
4. Open the live map. Markers refresh about every 20 seconds, and sooner when a location event arrives. A driver with an old fix is marked stale by the server. Open `/drivers-admin/live-map?driverId=<id>` and confirm only that driver is listed.
5. Assign a driver to an approved trip and walk Going → Arrive → Returning → End.

### Admin

1. Sign in to the admin dashboard. Confirm only the admin sections are shown.
2. Create an employee and confirm that employee can sign in.
3. Confirm this role's home is `/admin` and it does not open the drivers-admin live map.

---

## Pagination

List endpoints are paginated. `ApiClient.fetchAllPages` walks pages up to `PaginationConstants.maxPages` (50) at `defaultPerPage` (100).

Replace with true paged UI / infinite scroll in a later slice instead of unbounded aggregation.

---

## iOS check after this slice (this machine cannot build iOS)

There is no `Podfile` and no `GoogleService-Info.plist` in the repo. `ios/Runner/AppDelegate.swift` does not initialize a client database SDK. After `flutter pub get`, `ios/Runner/GeneratedPluginRegistrant.m` must not import `firebase_core` or `cloud_firestore`. On a Mac, run `flutter pub get`, then `flutter build ios --no-codesign` (or open the Xcode project) and confirm the registrant and the Pods no longer include those plugins.
