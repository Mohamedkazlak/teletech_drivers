<?php

declare(strict_types=1);

namespace App\Domain\Entities;

final readonly class DriverRecommendation
{
    public function __construct(
        public Driver $driver,
        public int $tier,
        public bool $hasFavoriteMatch,
        public bool $hasConflict,
        public bool $isOnActiveTrip,
        public bool $isUnavailable,
        public bool $needsConfirmation,
        public int $tripsThisWeek,
    ) {}
}
