<?php

declare(strict_types=1);

namespace App\Domain\Services;

/**
 * Pure geospatial helper (Haversine).
 */
final class HaversineDistance
{
    private const EARTH_RADIUS_METERS = 6371000.0;

    public function meters(float $latA, float $lngA, float $latB, float $lngB): float
    {
        $dLat = deg2rad($latB - $latA);
        $dLng = deg2rad($lngB - $lngA);
        $lat1 = deg2rad($latA);
        $lat2 = deg2rad($latB);

        $h = sin($dLat / 2) ** 2
            + cos($lat1) * cos($lat2) * sin($dLng / 2) ** 2;

        return 2 * self::EARTH_RADIUS_METERS * asin(sqrt($h));
    }
}
