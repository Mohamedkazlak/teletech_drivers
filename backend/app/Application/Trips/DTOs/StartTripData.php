<?php

declare(strict_types=1);

namespace App\Application\Trips\DTOs;

final readonly class StartTripData
{
    public function __construct(
        public string $tripId,
        public string $actorId,
        public float $startLat,
        public float $startLng,
    ) {}
}
