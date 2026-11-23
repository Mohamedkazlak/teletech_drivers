<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\LiveMapState;
use DateTimeImmutable;

final readonly class LiveMapDriver
{
    public function __construct(
        public Driver $driver,
        public ?Trip $trip,
        public LiveMapState $state,
        public ?float $lat,
        public ?float $lng,
        public ?float $heading,
        public ?float $speed,
        public ?float $accuracy,
        public ?DateTimeImmutable $updatedAt,
        public bool $isStale,
        public bool $isTracking,
    ) {}
}
