<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use DateTimeImmutable;

final readonly class DriverLocation
{
    public function __construct(
        public string $driverId,
        public ?string $tripId,
        public float $lat,
        public float $lng,
        public float $heading,
        public float $speed,
        public float $accuracy,
        public bool $isTracking,
        public ?DateTimeImmutable $updatedAt,
    ) {}
}
