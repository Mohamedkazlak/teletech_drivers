# Backend architecture

API-only Laravel 12 application using Clean Architecture layers.

## Layers and dependency rule

```
Http  -->  Application  -->  Domain
  |              |
  +----> Infrastructure ----+
```

- **Outer depends on inner. Never the reverse.**
- `Domain` must not import Laravel, Eloquent, or HTTP types.
- `Application` depends on Domain interfaces/DTOs only (never Eloquent models).
- `Infrastructure` implements Domain/Application contracts with Eloquent, Sanctum, Hash, etc.
- `Http` validates input, calls one Action, returns an API Resource.

## Folder map

| Path | Responsibility |
|------|----------------|
| `app/Domain/Enums` | Backed enums (roles, statuses, branches) |
| `app/Domain/Entities` | Pure domain objects |
| `app/Domain/Shared` | Shared domain value objects (e.g. pagination) |
| `app/Domain/Repositories` | Repository **interfaces** |
| `app/Domain/Services` | Domain services / business rules |
| `app/Domain/Exceptions` | Domain failures |
| `app/Application/**/DTOs` | Readonly input DTOs |
| `app/Application/**/Actions` | One use case per class (`execute`) |
| `app/Application/Contracts` | Application ports (hasher, token issuer) |
| `app/Infrastructure` | Eloquent repositories, Sanctum/Hash adapters |
| `app/Http` | Controllers, Form Requests, Resources, Middleware |
| `app/Models` | Eloquent persistence only |
| `app/Policies` | Authorization stubs (one per model) |

Bindings live in `AppServiceProvider` (interface → implementation).

## How to add a new use case

1. Add or extend a Domain repository interface / domain service if needed.
2. Create a readonly DTO under `Application/.../DTOs`.
3. Create an Action with a single public `execute` method; inject interfaces only.
4. Implement/adapt Infrastructure if a new port is required; bind it in `AppServiceProvider`.
5. Add a Form Request, thin Controller method, and API Resource.
6. Register the route under `routes/api.php`.
7. Add a unit test for the Action (fake repository) and a feature test for the endpoint.

Auth (`RegisterUserAction` + `UserRepositoryInterface` + `EloquentUserRepository`) is the **reference** pattern.

## Auth

- Sanctum personal access tokens (stateless). No Blade, no session auth for the API.
- `personal_access_tokens.tokenable_id` uses `uuidMorphs` so UUID users work with Sanctum.
- Inactive or soft-deleted users cannot log in; active middleware rejects their tokens with `401`.
- Soft-deleting a user sets `is_active=false`, `deleted_at`, `deleted_by`, and revokes **all** of that user's tokens.
- Role checks use `role:company_admin,drivers_admin` middleware alias; feature authorization uses Policies (`authorize()`).

## Places / headquarters

- Places are never hard-deleted; deactivate with `is_active=false`.
- **Headquarters uniqueness:** at most one place may be both `is_headquarters=true` and `is_active=true`. Setting a second active HQ is **rejected** with `422` (`ActiveHeadquartersExistsException`). We do **not** atomically replace the previous HQ.
- Deactivating the current HQ is allowed. Trip requests keep their stored place name/coordinates, so deactivating a place does not break history.

## Drivers / employees

- Creating a driver writes `users` + `driver_profiles` (+ favorite places pivot) in **one** DB transaction.
- `DriverResource` (private fields) vs `DriverSummaryResource` (no private fields) is chosen by `DriverResourceFactory` via `UserPolicy::viewPrivateDriverFields` — not by `if` role checks in the controller body.
- Drivers may read their own private profile only through `GET /api/auth/me/driver-profile`.

## Trip requests / trips

- Create request uses **Strategy + Factory** (`CreateTripRequestStrategyFactory`); drivers_admin create also inserts an unassigned trip in the same transaction.
- Trip lifecycle transitions live in Domain `TripStatusTransitions` (State). Assign/cancel and driver phases (start/arrive/start-return/end) all go through `assertTransition`.
- Trip report: `TripReportBuilder`. Recommendations: `DriverRecommendationService` + small Specifications. Availability HQ bands: `HqDistanceClassifier`. Live location lives only in `driver_locations` (no `trips.last_location`).
- Grouping suggestions: pure `GroupingSuggestionService` + Haversine; calendar day uses `APP_BUSINESS_TIMEZONE`.
- `TripResource` vs `TripSummaryResource` via `TripResourceFactory` + `TripPolicy::viewSensitiveFields` (hides routes/start coords from company_admin/admin).
- Concurrent approve/link/assign uses `lockForUpdate` inside one DB transaction. Wrong status / already linked → **409**.

## API docs

Client contract: `docs/API.md` (keep updated every phase).

## Error JSON shape

```json
{ "message": "...", "errors": { "field": ["..."] } }
```

`errors` is present for validation (`422`) and domain rule failures mapped to `422` (e.g. second headquarters). Auth (`401`), forbidden (`403`), and not-found (`404`) return `message` only. State conflicts return **`409`** with `message` only.
