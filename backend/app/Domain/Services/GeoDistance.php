<?php

declare(strict_types=1);

namespace App\Domain\Services;

/**
 * Domain facade over Haversine for availability / HQ distance.
 */
final class GeoDistance
{
    public function __construct(
        private readonly HaversineDistance $haversine = new HaversineDistance,
    ) {}

    public function meters(float $latA, float $lngA, float $latB, float $lngB): float
    {
        return $this->haversine->meters($latA, $lngA, $latB, $lngB);
    }
}
