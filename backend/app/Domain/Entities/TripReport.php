<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\TripStatus;
use DateTimeImmutable;

final readonly class TripReport
{
    /**
     * @param  list<TrackingPoint>  $drivenRoute
     */
    public function __construct(
        public TripStatus $status,
        public bool $isInProgress,
        public ?DateTimeImmutable $startedAt,
        public ?DateTimeImmutable $finishedAt,
        public ?int $totalDurationSeconds,
        public ?int $goingDurationSeconds,
        public ?int $waitingDurationSeconds,
        public ?int $returnDurationSeconds,
        public ?float $goingDistanceKm,
        public ?float $returnDistanceKm,
        public ?float $totalDistanceKm,
        public ?string $goingRoute,
        public ?string $returnRoute,
        public array $drivenRoute = [],
    ) {}
}
