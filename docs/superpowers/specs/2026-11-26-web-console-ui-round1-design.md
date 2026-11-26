# Web console UI, round 1: shared pieces, dashboard, bugs

Date: 2026-11-26. Scope: the React console in `web/`. Source review: two independent reviews of all pages (38 screenshots, three admin roles, EN/AR, 390 px), score 22/40.

## Why

The console's frame (sidebar, top bar, toasts, login) already carries the TeleTech "Ring & Route" look, but the inside of every page reads as a generic admin template: a tall stack of filters, a bordered table with three buttons per row, always-visible pagination, and walls of identical number tiles. Admins use this all day to dispatch trips and watch attendance. The goal is a console that looks distinctly TeleCars and is faster to scan, by fixing the shared building blocks once so every page improves together, then the dashboard, then known bugs.

## Goals

1. One shared filter bar used on every list page.
2. Lighter tables: row opens the item, secondary actions in a "⋯" menu, pagination only when needed, stacked cards on phones.
3. A Route cell and a trip phase indicator, used in every trip and request table, with one column order across roles.
4. Empty and error states that say why and offer a next step; error toasts that stay.
5. Purposeful motion following DESIGN.md.
6. Dashboard restructured around what needs action now.
7. Listed bugs fixed.
8. The console is named TeleCars.

## Non-goals (this round)

Dark mode; live map redesign; side drawers for details; bulk approve; attendance QR poster; keyboard shortcuts; driver profile restructure; page-specific items not listed below. These stay for later rounds.

## Anti-goals

- Decorative motion inside data pages (no scroll reveals, no tilt, no looping effects, no WebGL outside the auth pages).
- Breaking Arabic/RTL in any piece.
- Breaking existing tests or behaviour (URL-synced filters, realtime refresh, role guards).
- New runtime dependencies.

## Constraints

- Stack stays: React 18, Tailwind v4, `motion` (already installed), react-i18next, recharts. Tokens in `web/src/theme/tokens.css` and `web/src/components/ui/styles.ts`; new colours go into tokens, not hex literals.
- Motion tokens from DESIGN.md: easeOut `cubic-bezier(0.23,1,0.32,1)`, easeInOut `cubic-bezier(0.77,0,0.175,1)`, 120 / 180 / 260 / 420 ms. Exits faster than entrances. Never scale from 0 (≥ 0.92 with fade). Stagger delays 0, 50, 90, 120, 145, 165 ms then capped; first load only.
- Reduced motion: only fades and colour changes remain; JS-driven animation (motion, recharts) must also honour it.
- Every new string in both `en.ts` and `ar.ts`. Logical CSS properties only.
- Contrast ≥ 4.5:1; controls 44 px tall (`--control-height`), icon buttons ≥ 40 px.
- `npm --prefix web run lint`, `typecheck` and `test` stay green; existing tests are updated, not deleted, where markup changes.

## Approaches considered

- **A. Build the pieces in-house** on existing tokens and `motion`, borrowing React Bits / Uiverse components as copied source restyled to TeleTech tokens. No new dependencies; keeps the look; the "⋯" menu's keyboard behaviour is ours to build. **Chosen by Omar.**
- B. Add Radix primitives for menu/popover, rest in-house. Solid accessibility out of the box, but a new dependency and its animation model to fit to ours.

## The design

### 1. FilterBar (`components/ui/FilterBar.tsx`)

- One row (wraps on narrow screens): search input first (start side, flexible width, magnifier icon, clear "×"), then compact selects, then toggles, then a "Clear filters" text button that appears only when any filter differs from its default.
- Selects keep `FilterSelect` behaviour but get a compact variant: label visually inside or above at 12 px; total block height ≤ 64 px including label.
- "Include deleted" becomes a switch (Uiverse-style, restyled; real `<button role="switch" aria-checked>`).
- Period: `PeriodBar` becomes a segmented control (Week / Month / Year / All) with a sliding thumb (`motion` layout animation, easeInOut 260 ms) plus the range stepper; the stepper is hidden when the period is "All".
- Values still read/write the URL through `lib/use-list-params.ts`; Clear resets to defaults via the same path.
- The search slot is optional. It shows only where the endpoint supports `search` (drivers, employees, users, places, trip requests). Trips, My trips and Attendance have no server search, so they show no search box. No client-side filtering of one page of results. *(Claude's call: the round stays web-only.)*
- Each page passes its own period options; the control does not force Week/Month/Year/All everywhere.
- Applied to: Drivers, Employees, Users, Places, Trips (admin, company admin, drivers admin), Trip requests, Requested trips, My trips (all roles), Attendance, Driver reports.
- **Attendance specifics** *(Claude's call)*: the period control offers **Day · Week · Month · Year** (no All; the backend has none). Day is the default and means today. The stepper moves day by day, and Day sends only `date`, which the backend treats as a single day. This replaces the separate work-date input and period select. The raw driver-ID text field becomes a searchable driver picker backed by `GET /drivers?search=`. The dashboard's "Absent drivers" link opens Attendance on Day, today, status absent.

### 2. DataTable changes (`components/ui/DataTable.tsx`)

- `onRowClick?(row)` / `rowHref?(row)`: whole row is clickable with hover tint and a focusable primary cell link (keyboard: Enter on the link). Clicks inside the actions cell don't trigger the row. What a row opens *(Claude's call)*: trips and requests open their existing detail dialog (`TripDetailDialog`, `FleetTripDetail`, `RequestDetailDialog`); drivers open the driver profile route. Employees, Users and Places have no detail view, so their row opens the Edit dialog, and Edit leaves their "⋯" menu. No new detail views this round.
- `RowActions` component: zero or one visible inline action plus a "⋯" icon button opening a menu with the rest (Edit, Delete, Reset password, Export…). Menu: grows from the trigger corner (scale 0.95→1 + fade, 180 ms easeOut, origin flips in RTL), closes on Esc/outside click/selection, arrow keys move focus, focus returns to trigger, `aria-haspopup="menu"`, items `role="menuitem"`. Destructive items in `danger-ink`.
- Pagination footer hidden when `lastPage <= 1`; header shows a count ("3 results") when the API provides a total, else nothing.
- Below 640 px, rows render as stacked cards: primary column as title, other columns as label/value pairs, actions in the card's "⋯". Opt-in per column via `mobile: 'title' | 'meta' | 'hidden'`, default `meta`.
- Sticky header inside the table's scroll container.
- Row entrance stagger on first load only (see Motion); no animation on refetch.

### 3. RouteCell and TripPhase (`components/trips/RouteCell.tsx`, `TripPhase.tsx`)

- RouteCell: origin dot (filled `deepBlue`) → dashed connector → destination ring (`signal` ring), origin and destination names stacked or inline depending on width, truncated with full text in `title`. Scheduled time beneath in tabular figures. Mirrors in RTL (dot on the start side). Uses the localized place name where the API provides one; otherwise the name as stored.
- TripPhase: five small steps (assigned, going, at destination, returning, completed) as dots joined by a line; completed steps filled, the current one a ring with the existing slow pulse (only for in-progress trips, so long lists don't all pulse); label of the current phase beside it. Special states (unassigned, cancelled, awaiting report) show as a status chip instead of the steps. Accessible name: "Phase 2 of 5: going".
- One column order for every trip table: **When · Route · Driver · Phase · Actions** (drivers admin keeps People as an extra column after Route). Replaces the separate Status and Stage columns.
- Request tables use RouteCell too, plus a short "Waiting on" line under the status chip: pending requests wait on the company admin; approved requests with no trip yet wait on the drivers admin.
- Pagination count uses the API's `meta.total`, which every list returns.

### 4. Empty, error and feedback states

- `EmptyState` component (extends DataTable's `EmptyRoute`): mirrored in RTL, a one-line reason, optional action button (e.g. "Show all weeks", "Clear filters", "Request a trip").
- Error toasts: persist until dismissed, close button, `role="alert"`; success/info toasts keep auto-dismiss. Toasts accept an optional action (used for Undo later).
- Page-level error text uses `text-danger-ink` (LiveMapPage, AttendanceQrPage, others found by grep).
- Notifications page: real empty state; "Mark all as read" hidden when nothing is unread.

### 5. Motion

- AppShell: stop replaying `animate-rise` on every route change; route changes cross-fade content (opacity, 180 ms). First app load keeps the rise.
- List stagger on first load per DESIGN.md delays, opacity + 6 px rise, 260 ms easeOut.
- Numbers: a rolling-digit counter (React Bits "Counter"-style, rewritten on tokens) animates only when a value changes after first render (realtime or filter change), with a 600 ms `signal` tint flash; no count-up on first render, never from 0 to 0. Replaces CountUp on dashboard and tiles.
- Segmented period thumb and nav pill slide (easeInOut 260 ms).
- Menus/popovers grow from their trigger (account menu, notifications menu, RowActions).
- Buttons keep press 0.97; cards that are links lift 2 px on hover.
- Recharts animation disabled under reduced motion (`isAnimationActive`).
- Remove BlurText from the login subtitle (plain fade).

### 6. Dashboard (`pages/DashboardPage.tsx`)

- Hero stays (attendance today + on the road + waiting). Absent bar: only the absent segment uses warning colour; the track is neutral.
- Under it, an **Attention strip**: Unassigned trips, Pending requests, Unconfirmed trips, Absent drivers. Each is a link to the filtered list; warning tone only when > 0, quiet neutral when 0 ("All clear").
- One **inline totals line**: drivers · employees · places · completed today · completed this week.
- Remove the separate Drivers section (duplicates the hero) and the 17-tile grid.
- Replace the bar chart with **"On the road now"**: a short list of in-progress trips (RouteCell + driver + phase), empty state "No trips on the road right now". The trips-by-status chart is dropped from the dashboard. (Data: the dashboard endpoint doesn't provide this, so use `GET /trips?stage=in_progress`, first 5, linking to the full list.)
- Skeleton matches the new layout.

### 7. Bugs

- Arabic avatar initials: skip a leading "ال" on Arabic words (TopBar `initials()`); add a unit test.
- Global `:focus-visible` rule no longer overrides radius: drop the `border-radius` from it (outline follows the element's radius in modern browsers); inputs use their own focus ring and not the outline.
- Chart labels/RTL: moot once the chart leaves the dashboard; any remaining recharts usage mirrors in RTL (`reversed` x-axis, y-axis `orientation="right"`).
- Language toggle visible on phones (compact variant in TopBar).
- One date format: a shared `formatDate` / `formatDateTime` in `lib/format.ts` (e.g. "Wed 26 Nov", "Wed 26 Nov, 3:58 PM", localized), used in all tables. Times don't wrap ("3:58 م" stays on one line).
- `StatusMark` strike line origin flips in RTL.
- Dashboard status-bar segments animate `transform` only, not `width`.
- Small hit targets: language toggle buttons and favourite-place chips to ≥ 40 px.

### 8. Name

`app.name` becomes "TeleCars" (en) and "تيلي كارز" (ar); subtitle "TeleTech fleet console" / Arabic equivalent; `<title>` and login card updated. The TeleTech logo stays as the parent brand mark on login.

## Order of work

1. Bugs + naming (small, independent).
2. Motion foundation (AppShell, stagger helper, counter, menu animation).
3. FilterBar + PeriodBar, rolled out page by page.
4. DataTable + RowActions + mobile cards, rolled out page by page.
5. RouteCell + TripPhase + trip/request tables.
6. Empty/error states.
7. Dashboard.

Each step is verified with lint, typecheck, tests, and screenshots in EN, AR and 390 px.

## Left to the builder

Exact spacing values within the token scale, icon choices from `components/icons.tsx` (add icons there as needed), component file splits, test placement, and the exact Arabic wording (to be reviewed by Omar).
