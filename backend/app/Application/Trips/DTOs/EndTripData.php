<?php

declare(strict_types=1);

namespace App\Application\Trips\DTOs;

final readonly class EndTripData
{
    public function __construct(
        public string $tripId,
        public string $actorId,
        public int $returnDistanceM,
        public string $returnRoute,
    ) {}
}
