# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

- **Drivers** (primary for the mobile app): TeleTech company drivers. They check in and out at headquarters by scanning a QR code, run assigned trips phase by phase (start, arrive, return, end) and review completed trips and their stats. Often used in a car, in daylight, one-handed, between tasks.
- **Employees**: request trips and follow them.
- **Drivers admins, company admins, admins**: assign trips, manage drivers, review attendance. They mainly use the website; the app has screens for them too.

## Product Purpose

TeleCars assigns company cars and trips at TeleTech and records driver attendance. Success: a driver knows at a glance whether they are checked in, what trip is next, and what to tap to move it forward.

## Operating Context

- Attendance only counts inside the headquarters radius (GPS plus QR). Check-in and check-out happen once a day.
- Trips move through fixed phases: assigned → going → at destination → returning → completed. A live map and GPS sharing run during a trip.
- Bilingual: English and Arabic (RTL). Cairo time.
- Flutter app: Riverpod, go_router, flutter_animate, fl_chart. Laravel API and a React website share the database.

## Brand Commitments

- TeleTech is the parent brand; its logo is the blue ellipse wordmark with the concentric-ring mark. Keep TeleTech blue (`#0B4DA2`) as the primary colour.
- The app is called TeleCars.

## Evidence on Hand

- Logo: `assets/images/teletech_logo.png` (low-resolution raster on white). App icon: `assets/branding/`.
- No photography, testimonials or marketing copy. Do not invent any.

## Product Principles

1. Status first: the driver's current state (attendance, trip phase) is the first thing on every screen.
2. One primary action per screen, always within thumb reach.
3. Motion confirms what happened and never makes a driver wait.
4. Arabic is a first-class layout, not a mirror afterthought.

## Accessibility & Inclusion

- Respect the system "Remove animations" setting (handled through `AppAnimations`).
- Text contrast ≥ 4.5:1, touch targets ≥ 48 dp, text scales with the system font size.
