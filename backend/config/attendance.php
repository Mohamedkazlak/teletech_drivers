<?php

declare(strict_types=1);

$offDays = array_values(array_filter(
    array_map(
        static fn (string $day): int => (int) trim($day),
        explode(',', (string) env('ATTENDANCE_WEEKLY_OFF_DAYS', '5')),
    ),
    static fn (int $day): bool => $day >= 0 && $day <= 6,
));

return [
    /*
    | Company Headquarters. A scan is accepted only when the driver's
    | reported position is inside this radius. Africa/Cairo is the clock.
    */
    'hq_lat' => (float) env('ATTENDANCE_HQ_LAT', 30.0444),
    'hq_lng' => (float) env('ATTENDANCE_HQ_LNG', 31.2357),
    'radius_m' => (int) env('ATTENDANCE_RADIUS_M', 150),
    'max_accuracy_m' => (float) env('ATTENDANCE_MAX_ACCURACY_M', 50),

    /*
    | Carbon / PHP day-of-week: 0 = Sunday … 6 = Saturday. 5 = Friday.
    | Off days are not counted as absent.
    */
    'weekly_off_days' => $offDays === [] ? [5] : $offDays,

    /*
    | Printed QR: telecars-attendance:v{version}:{hmac}.
    | Bump the version to invalidate codes that are already printed.
    | An empty secret is derived from APP_KEY.
    */
    'qr_secret' => env('ATTENDANCE_QR_SECRET'),
    'qr_version' => (int) env('ATTENDANCE_QR_VERSION', 1),
    'hq_name' => env('ATTENDANCE_HQ_NAME', 'Company Headquarters'),
];
