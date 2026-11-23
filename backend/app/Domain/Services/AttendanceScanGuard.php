<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Exceptions\AttendanceRejectedException;

/**
 * Scan checks, in order: QR signature, mock flag, accuracy, then
 * server-side distance to Company Headquarters.
 */
final class AttendanceScanGuard
{
    public function __construct(
        private readonly AttendanceQr $qr,
        private readonly GeoDistance $distance,
    ) {}

    public function assertAcceptable(
        string $qrPayload,
        float $lat,
        float $lng,
        float $accuracyM,
        bool $isMocked,
    ): int {
        $this->qr->assertValid($qrPayload);

        if ($isMocked) {
            throw new AttendanceRejectedException(
                'mock_location',
                __('messages.attendance_mock_location'),
            );
        }

        $maxAccuracy = (float) config('attendance.max_accuracy_m', 50);
        if (! is_finite($accuracyM) || $accuracyM < 0 || $accuracyM > $maxAccuracy) {
            throw new AttendanceRejectedException(
                'low_accuracy',
                __('messages.attendance_low_accuracy'),
            );
        }

        $hqLat = (float) config('attendance.hq_lat');
        $hqLng = (float) config('attendance.hq_lng');
        $meters = $this->distance->meters($lat, $lng, $hqLat, $hqLng);
        $radius = (int) config('attendance.radius_m', 150);
        $rounded = (int) round($meters);

        if ($meters > $radius) {
            throw new AttendanceRejectedException(
                'outside_radius',
                __('messages.attendance_outside_radius', [
                    'distance' => $rounded,
                    'radius' => $radius,
                ]),
                distanceM: $rounded,
                radiusM: $radius,
            );
        }

        return $rounded;
    }
}
