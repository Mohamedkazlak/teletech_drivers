<?php

declare(strict_types=1);

namespace App\Application\DriverLocations\DTOs;

final readonly class PublishDriverLocationData
{
    public function __construct(
        public string $driverId,
        public float $lat,
        public float $lng,
        public float $heading,
        public float $speed,
        public float $accuracy,
        public bool $isTracking,
        public ?string $tripId,
    ) {}
}
