<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use DateTimeImmutable;

/**
 * Completed trip facts used by StatsAggregator.
 * finished_at is required because only trips finished inside the period count.
 */
final readonly class CountableTrip
{
    public function __construct(
        public ?DateTimeImmutable $goingStartedAt,
        public DateTimeImmutable $finishedAt,
        public ?int $totalDistanceM,
    ) {}
}
