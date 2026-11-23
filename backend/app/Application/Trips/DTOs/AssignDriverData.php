<?php

declare(strict_types=1);

namespace App\Application\Trips\DTOs;

final readonly class AssignDriverData
{
    public function __construct(
        public string $tripId,
        public string $driverId,
        public string $actorId,
    ) {}
}
