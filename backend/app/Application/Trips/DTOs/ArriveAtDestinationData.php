<?php

declare(strict_types=1);

namespace App\Application\Trips\DTOs;

final readonly class ArriveAtDestinationData
{
    public function __construct(
        public string $tripId,
        public string $actorId,
        public int $goingDistanceM,
        public string $goingRoute,
    ) {}
}
