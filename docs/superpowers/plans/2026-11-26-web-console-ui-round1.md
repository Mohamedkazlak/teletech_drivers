# Web Console UI Round 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every page of the React console shared, TeleCars-styled building blocks (filter bar, lighter tables, Route cell, trip phase, states, motion), rebuild the dashboard around what needs action, fix the listed bugs, and rename the console TeleCars.

**Architecture:** New primitives live in `web/src/components/ui/` and `web/src/components/trips/`; pages adopt them one at a time. Motion uses the `motion` package already installed and the tokens in `web/src/theme/tokens.css`. No new runtime dependencies.

**Tech Stack:** React 18, TypeScript, Tailwind v4, `motion/react`, react-i18next, react-query, react-router v6, Vitest + Testing Library.

**Spec:** `docs/superpowers/specs/2026-11-26-web-console-ui-round1-design.md` (read it with this plan).

All commands run from `web/`. "Checks" means: `npm run lint && npm run typecheck && npm test` all pass.

## Global Constraints

- No new runtime dependencies. React Bits / Uiverse pieces are copied source, restyled to tokens.
- Colours come from tokens (`--color-*` in `tokens.css`); add a token rather than a hex literal.
- Motion tokens: easeOut `cubic-bezier(0.23,1,0.32,1)` (`var(--ease-out)`), easeInOut `cubic-bezier(0.77,0,0.175,1)`; durations 120 / 180 / 260 / 420 ms. Exits faster than entrances. Never scale from 0 (start ≥ 0.92 with a fade).
- Stagger delays: 0, 50, 90, 120, 145, 165 ms, then capped at 165; first load only.
- Reduced motion: only opacity and colour changes remain, including JS animation (`useReducedMotion()` from `motion/react`; recharts `isAnimationActive={false}`).
- Every new string exists in both `i18n/locales/en.ts` and `ar.ts`.
- Logical properties only (`ms-/me-/ps-/pe-/start-/end-`, `rtl:` variants); directional visuals mirror in Arabic.
- Text contrast ≥ 4.5:1; inputs and buttons `h-[var(--control-height)]` (44 px); icon buttons ≥ 40 px.
- Existing behaviour stays: filters synced to the URL via `useListParams`, realtime refresh, role guards. Existing tests are updated when markup changes, never deleted to pass.
- Dates and times display in Africa/Cairo.

## Review Focus

1. **Arabic layout of every new piece**: RouteCell, TripPhase, RowActions menu origin, segmented thumb, stepper chevrons must mirror. Each component task includes an `dir="rtl"` test or assertion.
2. **Keyboard use of the "⋯" menu and clickable rows**: Tab reaches the row link and the menu trigger; Enter opens; arrows move; Esc closes and returns focus; clicking a menu item never also fires the row click. Pinned in Task 6 tests.
3. **Filters in the URL survive the new FilterBar**: reloading a filtered URL shows the same filters and "Clear filters" removes every filter key and `page`. Pinned in Task 4 tests.
4. **Zero values**: dashboard counts of 0 show the calm state, no count-up animation, no warning tone. Pinned in Tasks 3 and 9.
5. **Long or missing place names**: RouteCell with a 60-character name truncates with a `title`; a null pickup or destination shows "—" not "null". Pinned in Task 7.

---

### Task 1: Bugs and naming

**Files:**
- Modify: `src/components/layout/TopBar.tsx:21-27` (export `initials`), `src/index.css:35-39`, `src/i18n/locales/en.ts`, `src/i18n/locales/ar.ts`, `index.html`, `src/components/reactbits/StatusMark.tsx:202`, `src/components/language/LanguageToggle.tsx`, `src/pages/drivers-admin/FavoritePlacesField.tsx:67`, `src/lib/format.ts`
- Create: `src/lib/initials.ts`, `src/lib/initials.test.ts`, `src/lib/format.test.ts`

**Interfaces:**
- Produces: `initials(name: string): string` in `src/lib/initials.ts`; `formatDate(value: string | null | undefined, language: string): string` and `formatDateTime(value: string | null | undefined, language: string): string` in `src/lib/format.ts` (Cairo zone; "Wed 26 Nov" / "Wed 26 Nov, 3:58 PM"; empty input → `'—'`).

- [ ] **Step 1: Write failing tests**

```ts
// initials.test.ts
expect(initials('مدير النظام')).toBe('من')
expect(initials('مسؤول السائقين')).toBe('مس')
expect(initials('Test Admin')).toBe('TA')
expect(initials('omar')).toBe('O')
expect(initials('  ')).toBe('?')
// format.test.ts
expect(formatDate('2026-11-26T13:58:00Z', 'en')).toBe('Wed 26 Nov')
expect(formatDateTime('2026-11-26T13:58:00Z', 'en')).toBe('Wed 26 Nov, 3:58 PM')
expect(formatDateTime(null, 'en')).toBe('—')
expect(formatDateTime('2026-11-26T13:58:00Z', 'ar')).not.toMatch(/\n/)
```

- [ ] **Step 2: Run `npx vitest run src/lib/initials.test.ts src/lib/format.test.ts`.** Expected: FAIL (module/function missing).
- [ ] **Step 3: Implement.** `initials` strips a leading `ال` from an Arabic word before taking its first letter. `formatDate`/`formatDateTime` use `Intl.DateTimeFormat` with `timeZone: 'Africa/Cairo'`, `weekday: 'short', day: 'numeric', month: 'short'` (plus `hour: 'numeric', minute: '2-digit'`), joined as in the test. TopBar imports `initials` from the new module.
- [ ] **Step 4: Apply the rest of the bug fixes.**
  - `index.css`: remove `border-radius: 6px` from `:focus-visible`; add `input:focus-visible, select:focus-visible, textarea:focus-visible { outline: none; }` (they keep the `controlClass` focus ring).
  - Naming: `app.name` → `'TeleCars'` / `'تيلي كارز'`; `app.tagline` → `'TeleTech fleet console'` / `'منصة أسطول تيلي تك'`; `index.html` `<title>TeleCars</title>`.
  - `StatusMark.tsx:202`: add `rtl:origin-right` beside `origin-left`.
  - `LanguageToggle`: buttons `h-10`; add `compact` prop (`compact?: boolean`) rendering "EN"/"ع" labels; TopBar shows the compact toggle below `sm` instead of hiding it.
  - `FavoritePlacesField.tsx:67`: chip remove button min 40 px hit area (`min-h-10`).
  - Page-level red text: replace `text-danger` with `text-danger-ink` where used on plain text (`grep -rn "text-danger\b" src/pages`).
- [ ] **Step 5: Run checks.** Update tests that assert "TeleTech Drivers". Expected: all green.
- [ ] **Step 6: Commit** `fix(web): Arabic initials, focus radius, Cairo date format, TeleCars name`.

### Task 2: Motion foundation

**Files:**
- Create: `src/lib/motion.ts`, `src/lib/motion.test.ts`, `src/components/ui/Counter.tsx`, `src/components/ui/Counter.test.tsx`
- Modify: `src/components/layout/AppShell.tsx:66-73`, `src/index.css` (add `.animate-fade-quick` 180 ms opacity keyframe if not present), `src/components/layout/AuthFrame.tsx` (BlurText → plain `animate-fade`), `src/components/ui/styles.ts` (`menuPanelClass` origin stays; scale-from 0.95)

**Interfaces:**
- Produces: `staggerDelay(index: number): number` (ms, from `[0,50,90,120,145,165]`, capped); `EASE_OUT = [0.23,1,0.32,1] as const`; `EASE_IN_OUT = [0.77,0,0.175,1] as const`; `DURATION = { press: 0.12, quick: 0.18, standard: 0.26, emphasized: 0.42 } as const` in `src/lib/motion.ts`.
- Produces: `<Counter value: number; className?: string />` — renders the number in tabular figures; on first render shows `value` with no animation; when `value` changes, rolls digits (motion, 420 ms easeOut) and adds `data-changed="true"` for 600 ms (styled with a `signal` tint). Under reduced motion it swaps instantly.

- [ ] **Step 1: Write failing tests**

```ts
expect([0,1,2,3,4,5,6,9].map(staggerDelay)).toEqual([0,50,90,120,145,165,165,165])
// Counter.test.tsx
render(<Counter value={0} />) → screen.getByText('0'); element has no data-changed
rerender(<Counter value={3} />) → findByText('3'); element has data-changed="true"
```

- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement `src/lib/motion.ts` and `Counter.tsx`.** Counter keeps an accessible `aria-label`/text of the final value at all times (screen readers never read intermediate digits).
- [ ] **Step 4: AppShell.** Remove `key={location.pathname}` and `animate-rise` from `<main>`; wrap `<Outlet />` in a `<div key={location.pathname} className="animate-fade-quick">` and keep `animate-rise` only for the very first mount (a `useRef` flag).
- [ ] **Step 5: Run checks.** Expected: green.
- [ ] **Step 6: Commit** `feat(web): motion tokens, Counter, calmer route transitions`.

### Task 3: Segmented PeriodControl

**Files:**
- Modify: `src/components/ui/PeriodBar.tsx` (rename export to `PeriodControl`, keep `PeriodBar` as an alias export until Task 4 finishes migrating)
- Create: `src/components/ui/PeriodControl.test.tsx`

**Interfaces:**
- Consumes: `PeriodKind`, `PeriodSelection`, `shiftAnchor`, `formatDateParam`, `parseDateParam` from `src/lib/period.ts`; `EASE_IN_OUT`, `DURATION` from Task 2.
- Produces: `<PeriodControl value: PeriodSelection; onChange: (v: PeriodSelection) => void; periods: readonly PeriodKind[] />` — a `role="radiogroup"` of buttons (`role="radio"`, `aria-checked`) with a sliding thumb (`motion` `layoutId`, easeInOut 260 ms), followed by the range stepper; the stepper is not rendered when `value.period === 'all'`. Day shows a single date ("Wed 26 Nov"; "Today" when it is today in Cairo).

- [ ] **Step 1: Failing tests**: clicking "Month" calls `onChange({ period: 'month', date })`; with `period: 'all'` there is no "Previous" button; with `periods={['day','week','month','year']}` there is no "All" radio; in `dir="rtl"` the previous button shows the end-pointing chevron (`ChevronStartIcon` already mirrors — assert it is present).
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Arrow keys move the checked radio (roving tabindex).
- [ ] **Step 4: Run checks.** Expected: green.
- [ ] **Step 5: Commit** `feat(web): segmented period control`.

### Task 4: FilterBar and rollout

**Files:**
- Create: `src/components/ui/FilterBar.tsx`, `src/components/ui/Switch.tsx`, `src/components/ui/FilterBar.test.tsx`
- Modify: `src/components/ui/FilterSelect.tsx` (add `compact` variant), `src/components/ui/IncludeDeletedToggle.tsx` (use `Switch`), and each list page: `pages/drivers-admin/{DriversPage,TripsPage,MyTripsPage,RequestsPage,AttendancePage}.tsx`, `pages/admin/{EmployeesPage,UsersPage,TripRequestsPage}.tsx`, `pages/company-admin/{TripsPage,MyTripsPage,PlacesPage,RequestedTripsPage,DriverReportsPage}.tsx`, `pages/drivers-admin/DriverProfilePage.tsx` (PeriodBar → PeriodControl)
- Create: `src/components/ui/DriverPicker.tsx`

**Interfaces:**
- Consumes: `useListParams()` (`params`, `set(updates, resetPage?)`), `PeriodControl` (Task 3).
- Produces:
  - `<FilterBar search?: { value: string; onChange: (v: string) => void; label: string }; activeCount: number; onClear: () => void; children: ReactNode />` — one wrapping row: search (start side, magnifier, "×" clear) then `children`; a "Clear filters" text button rendered only when `activeCount > 0`.
  - `<Switch checked: boolean; onChange: (v: boolean) => void; label: string />` — `<button role="switch" aria-checked>`, thumb slides 180 ms.
  - `<FilterSelect compact?: boolean … />` — compact: 12 px label, block ≤ 64 px tall.
  - `<DriverPicker value: string | null; onChange: (driverId: string | null) => void />` — searchable combobox over `GET /drivers?search=` (existing drivers API hook), `role="combobox"`, shows driver name, clearable.
- Page rule: search slot only on Drivers, Employees, Users, Places, Trip requests (admin), Requests (drivers admin), Requested trips (company admin). Trips, My trips, Attendance: no search.
- Attendance: `PeriodControl periods={['day','week','month','year']}`, default `day`; Day sends only `date` (today when absent); week/month/year send `period` + `date`. Remove the work-date input and the period select. Driver text field → `DriverPicker` writing `driver`.

- [ ] **Step 1: Failing tests (FilterBar.test.tsx)**: with `activeCount={0}` no "Clear filters"; with `activeCount={2}` clicking it calls `onClear`; typing in search calls `onChange`; the "×" clears it; `Switch` toggles `aria-checked`.
- [ ] **Step 2: Failing page test (extend `pages/drivers-admin/drivers.test.tsx`)**: rendered at `/drivers-admin/drivers?attendance=checked_in&search=om&page=2`, the select shows checked-in and the search shows "om"; clicking "Clear filters" leaves the URL with no `attendance`, `search` or `page`.
- [ ] **Step 3: Failing page test (extend `pages/drivers-admin/attendance.test.tsx`)**: with no params the request is `/attendance` with `date` = today (Cairo) and no `period`; choosing "Week" sends `period=week`; no element with label "Work date" in the filter row.
- [ ] **Step 4: Run them.** Expected: FAIL.
- [ ] **Step 5: Implement components, then migrate pages one by one**, running that page's test file after each. `activeCount` per page = number of its filter keys present in `params` (excluding `page`); `onClear` = `set({ …each key: null })`.
- [ ] **Step 6: Delete the `PeriodBar` alias** once no page imports it.
- [ ] **Step 7: Run checks.** Expected: green.
- [ ] **Step 8: Commit** `feat(web): shared FilterBar across list pages`.

### Task 5: EmptyState and toasts

**Files:**
- Create: `src/components/ui/EmptyState.tsx`, `src/components/ui/EmptyState.test.tsx`, `src/components/ui/ToastProvider.test.tsx`
- Modify: `src/components/ui/DataTable.tsx` (move `EmptyRoute` into EmptyState), `src/components/ui/ToastProvider.tsx`, `src/components/ui/toast-context.ts`, `src/pages/NotificationsPage.tsx`, `src/pages/LiveMapPage.tsx:61`, `src/pages/drivers-admin/AttendanceQrPage.tsx:27`

**Interfaces:**
- Produces: `<EmptyState message: string; action?: { label: string; onClick?: () => void; to?: string } />` — route drawing mirrored in RTL (`rtl:-scale-x-100`), message, optional button or link.
- Produces: `ToastApi = (message: string, tone?: ToastTone, options?: { action?: { label: string; onClick: () => void } }) => void` (backwards compatible). Error toasts: no auto-dismiss, close button (`aria-label` "Close"), container item `role="alert"`. Success/info: 4 s auto-dismiss as today.
- Produces: DataTable prop `empty?: { message: string; action?: EmptyStateAction }` (replaces `emptyLabel`; keep `emptyLabel` working as `message` for unmigrated callers).

- [ ] **Step 1: Failing tests**: an error toast is still present after advancing fake timers 10 s, has `role="alert"`, and disappears after clicking Close; a success toast is gone after 4.2 s; EmptyState with `action.to` renders a link with that href.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Notifications: EmptyState when the list is empty; hide "Mark all as read" when unread count is 0. Page error paragraphs use `text-danger-ink`. Give every list page an empty message with a next step where one exists (Trips: "Show all weeks" sets `period=all`; filtered lists: "Clear filters"; My trips: "Request a trip" opens the existing request dialog).
- [ ] **Step 4: Run checks.** Expected: green.
- [ ] **Step 5: Commit** `feat(web): empty states with next steps, persistent error toasts`.

### Task 6: DataTable rows, RowActions, mobile cards

**Files:**
- Create: `src/components/ui/RowActions.tsx`, `src/components/ui/RowActions.test.tsx`, `src/components/ui/DataTable.test.tsx`
- Modify: `src/components/ui/DataTable.tsx`, and every page using `DataTable` (14 files, `grep -rl DataTable src/pages`)

**Interfaces:**
- Consumes: `staggerDelay`, `DURATION`, `EASE_OUT` (Task 2); `EmptyState` (Task 5).
- Produces (DataTable additions):
  - `Column<T>.mobile?: 'title' | 'meta' | 'hidden'` (default `'meta'`); `Column<T>.isActions?: boolean`.
  - `onRowClick?: (row: T) => void` — row gets `cursor-pointer` and hover tint; clicks whose target is inside a `[data-row-actions]` element are ignored. The `title` column's content is wrapped by the page in a real `<Link>` or `<button>` so keyboard users reach it.
  - `total?: number` — when given, header shows "{{count}} results"; pagination footer renders only when `lastPage > 1`.
  - Sticky `<thead>`; rows fade/rise in with `staggerDelay(index)` on the first successful load only (not on refetch, not under reduced motion).
  - Below 640 px (`useMediaQuery('(max-width: 639px)')`): renders a list of cards (title column as heading, `meta` columns as label/value pairs, actions column top-end).
- Produces: `<RowActions primary?: ReactNode; items: { label: string; onSelect: () => void; danger?: boolean; disabled?: boolean }[]; label: string />` — wrapper has `data-row-actions`; "⋯" `iconButtonClass` trigger with `aria-haspopup="menu"` and `aria-expanded`; menu `role="menu"`, items `role="menuitem"`; ArrowUp/Down/Home/End move focus; Esc and outside click close and return focus to the trigger; opens with scale 0.95→1 + fade 180 ms easeOut from the trigger's end corner (`origin-top-right`, `rtl:origin-top-left`); flips upward when there is no room below.
- Page rules: trips/requests rows → their existing detail dialog; driver rows → driver profile route; Employees/Users/Places rows → Edit dialog (Edit not in the menu there). Delete is always a `danger` item that opens the existing ConfirmDialog. Users: the signed-in user's row shows a "You" chip and no actions.

- [ ] **Step 1: Failing tests (RowActions.test.tsx)**: Enter on trigger opens menu and focuses first item; ArrowDown moves focus; Esc closes and focuses trigger; selecting an item calls `onSelect` once.
- [ ] **Step 2: Failing tests (DataTable.test.tsx)**: clicking a cell calls `onRowClick(row)`; clicking inside RowActions does not; with `lastPage={1}` there is no "Next" button; with `total={3}` the text "3 results" shows; with `window.matchMedia` mocked to mobile, rows render as `listitem`s with the title column as a heading.
- [ ] **Step 3: Run.** Expected: FAIL.
- [ ] **Step 4: Implement DataTable and RowActions.**
- [ ] **Step 5: Migrate pages one at a time** (replace View/Edit/Delete buttons with row click + RowActions; pass `total={data.meta.total}`; set `mobile` on columns), running each page's existing test file after each and updating button-name queries (e.g. `getByRole('button', {name: 'Edit'})` → open "⋯" then `getByRole('menuitem', {name: 'Edit'})`).
- [ ] **Step 6: Run checks.** Expected: green.
- [ ] **Step 7: Commit** `feat(web): clickable rows, row action menu, mobile cards`.

### Task 7: RouteCell, TripPhase, trip and request tables

**Files:**
- Create: `src/components/trips/RouteCell.tsx`, `src/components/trips/TripPhase.tsx`, `src/components/trips/trip-columns.tsx`, `src/components/trips/RouteCell.test.tsx`, `src/components/trips/TripPhase.test.tsx`
- Modify: `pages/company-admin/{TripsPage,MyTripsPage,RequestedTripsPage}.tsx`, `pages/drivers-admin/{TripsPage,MyTripsPage,RequestsPage}.tsx`, `pages/admin/TripRequestsPage.tsx`, `src/i18n/locales/{en,ar}.ts`

**Interfaces:**
- Consumes: `formatDateTime` (Task 1), `Column<T>` with `mobile` (Task 6), `TripStatus`, `TripSummary`, `TripRequest`.
- Produces: `<RouteCell from: string | null; to: string | null; when?: string | null />` — origin dot (`bg-deep`) → dashed line → destination ring (`border-signal`), names truncated with `title`, `when` beneath via `formatDateTime`, null names render "—", `rtl:-scale-x-100` on the connector only (text not mirrored).
- Produces: `<TripPhase status: TripStatus; confirmation?: TripConfirmationStatus | null />` — for `assigned | going | at_destination | returning | completed`: five dots joined by a line, steps up to the current filled, current a ring (pulse only for `going | at_destination | returning`, none under reduced motion), current label beside; accessible name `t('trips.phaseOf', { step, total: 5, label })` ("Phase 2 of 5: Going"). For `unassigned | cancelled`, and `completed` with confirmation `pending`, render the existing `StatusBadge` instead.
- Produces: `tripColumns(t, language, opts: { includePeople?: boolean; actions: (trip) => ReactNode }): Column<TripSummary>[]` returning **When · Route · (People) · Driver · Phase · Actions**; When is sortable by `scheduled_at`.
- Requests: route column uses `RouteCell from={req.pickup.name} to={req.destination.name} when={req.requested_at}`; status cell adds a muted line `t('requests.waitingOn.company')` when `status === 'pending'`, `t('requests.waitingOn.drivers')` when `status === 'approved' && !trip_id`.

- [ ] **Step 1: Failing tests**: TripPhase `status="going"` has accessible name "Phase 2 of 5: Going"; `status="unassigned"` renders the badge text "Unassigned"; RouteCell with `from={null}` shows "—"; a 60-char name has a `title` equal to the full name; in a `dir="rtl"` wrapper the connector has the mirror class.
- [ ] **Step 2: Failing page test** (extend `pages/company-admin/trips.test.tsx` and `pages/drivers-admin/trips.test.tsx`): column headers in order `When, Route, Driver, Phase, Actions` (drivers admin: `When, Route, People, Driver, Phase, Actions`).
- [ ] **Step 3: Run.** Expected: FAIL.
- [ ] **Step 4: Implement and migrate the trip and request tables.** Remove the separate Status and Stage columns. Keep the stage filter values unchanged (the URL key `stage` stays).
- [ ] **Step 5: Run checks.** Expected: green.
- [ ] **Step 6: Commit** `feat(web): Route cell and trip phase in every trip table`.

### Task 8: Menus grow from their trigger

**Files:**
- Modify: `src/components/layout/TopBar.tsx` (account menu), `src/components/notifications/NotificationMenu.tsx`, `src/components/ui/styles.ts`

**Interfaces:**
- Consumes: the open/close animation from RowActions (Task 6) — extract it to `src/components/ui/MenuPanel.tsx`: `<MenuPanel open: boolean; align: 'end' | 'start'; children />` (mount/unmount with `AnimatePresence`, 180 ms in / 120 ms out). RowActions switches to it in this task.

- [ ] **Step 1:** Replace `menuPanelClass` + `animate-pop` in the three menus with `MenuPanel`.
- [ ] **Step 2: Run checks.** Expected: green (existing notifications tests unchanged).
- [ ] **Step 3: Commit** `feat(web): menus open from their trigger`.

### Task 9: Dashboard

**Files:**
- Modify: `src/pages/DashboardPage.tsx`, `src/pages/dashboard.test.tsx`, `src/i18n/locales/{en,ar}.ts`
- Delete (if nothing else imports them): `src/components/charts/BarChartCard.tsx`, `src/components/reactbits/CountUp.tsx`, `src/components/reactbits/BlurText.tsx`

**Interfaces:**
- Consumes: `AdminDashboard` from `useAdminDashboard()`; `Counter` (Task 2); `RouteCell`, `TripPhase` (Task 7); `EmptyState` (Task 5); trips list API with `stage=in_progress`, `per_page=5`.

Layout:
1. Hero (kept): attendance today. The bar track is neutral; only the checked-in (success), checked-out (signal) and absent (warning) segments are coloured by their share. Segments animate `transform: scaleX` only (no width transition). Numbers via `Counter`.
2. **Attention strip**, four links:
   - Unassigned trips → `/admin/trips?stage=unassigned` (`trips.unassigned`)
   - Pending requests → `/admin/trip-requests?status=pending` (`requests.pending`)
   - Unconfirmed trips → `/admin/trips?unconfirmed=true` (`unconfirmed_trips`)
   - Absent drivers → `/admin/attendance?status=absent` (Day, today is the Attendance default) (`drivers.absent`)
   Each: warning tone + `Counter` when > 0; neutral with "All clear" when 0.
3. **Totals line**: drivers · employees · places · completed today · completed this week, each a link to its list.
4. **On the road now**: up to 5 in-progress trips (RouteCell, driver name, TripPhase); "View all" → `/admin/trips?stage=in_progress`; EmptyState "No trips on the road right now".
5. Skeleton mirrors this layout.

- [ ] **Step 1: Update `dashboard.test.tsx` first** (remove the BarChartCard mock): with the fixture summary, the attention strip shows links named with 2, 8, 14, 3 and the correct hrefs; a summary with all zeros shows four "All clear" items and no element with `data-tone="warning"`; the totals line shows 10, 12, 3, 7, 9; with the trips request returning one in-progress trip, its route text appears; with none, "No trips on the road right now".
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Stagger the attention items and totals on first load (Task 2 delays). Attention items are linked cards: lift 2 px on hover (`hover:-translate-y-0.5`, 180 ms easeOut, none under reduced motion) and press 0.97.
- [ ] **Step 4: Run checks.** Expected: green.
- [ ] **Step 5: Commit** `feat(web): dashboard built around what needs action`.

### Task 10: Visual verification

- [ ] **Step 1:** Re-run the screenshot script (session scratchpad `shots.mjs`, or an equivalent Playwright script against `http://localhost:5173` with the local test accounts) for every page, EN + AR, and 390 px for Dashboard, Trips, Drivers.
- [ ] **Step 2:** Check each shot against the Global Constraints and Review Focus; fix and re-shoot until clean.
- [ ] **Step 3:** Run `npm run lint && npm run typecheck && npm test && npm run build`. Expected: all pass.
- [ ] **Step 4: Commit** any fixes `fix(web): round 1 visual fixes`.
