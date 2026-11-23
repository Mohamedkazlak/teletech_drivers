<?php

declare(strict_types=1);

return [
    'business_timezone' => env('APP_BUSINESS_TIMEZONE', 'Africa/Cairo'),

    /*
    | Live-map stale threshold: a driver_locations.updated_at older than this
    | many seconds is flagged is_stale=true (Flutter MapDefaults.staleThreshold).
    */
    'location_stale_seconds' => (int) env('TELETECH_LOCATION_STALE_SECONDS', 60),

    /*
    | Availability HQ distance bands (meters). Clients must use distance_band
    | from the API; near ≤ hq_near_meters, medium ≤ hq_medium_meters, else far.
    */
    'hq_near_meters' => (int) env('TELETECH_HQ_NEAR_METERS', 200),
    'hq_medium_meters' => (int) env('TELETECH_HQ_MEDIUM_METERS', 1000),

    /*
    | Driver recommendation schedule-conflict half-window around scheduled_at.
    | Flutter DriverScheduleConflict.window = 2 hours (inclusive).
    */
    'schedule_conflict_window_hours' => (int) env('TELETECH_SCHEDULE_CONFLICT_WINDOW_HOURS', 2),

    /*
    | Live location accuracy caps (meters). First publish (no existing row) uses
    | the larger limit; subsequent publishes use location_accuracy_max_meters.
    | Mirrors Flutter location_tracking_controller (500 / 50).
    */
    'location_accuracy_max_meters' => (float) env('TELETECH_LOCATION_ACCURACY_MAX_METERS', 50),
    'location_first_publish_accuracy_max_meters' => (float) env(
        'TELETECH_LOCATION_FIRST_PUBLISH_ACCURACY_MAX_METERS',
        500,
    ),

    /*
    | Max length of an encoded Google polyline string on arrive/end.
    | ~100k chars comfortably covers multi-hour tracks at ~15s samples while
    | staying well under typical MySQL TEXT limits (~64 KiB–64 MiB depending
    | on column type). Routes use text columns.
    */
    'polyline_max_length' => (int) env('TELETECH_POLYLINE_MAX_LENGTH', 100_000),

    /*
    | Laravel throttle for PUT /api/driver-location.
    | Client publishes about every 8 s, or after 20 m (never faster than 6 s).
    | Allow 12/min per user for that cadence plus a short burst.
    */
    'driver_location_throttle_per_minute' => (int) env(
        'TELETECH_DRIVER_LOCATION_THROTTLE_PER_MINUTE',
        12,
    ),
];
