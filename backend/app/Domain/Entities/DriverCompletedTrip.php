<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use DateTimeImmutable;

final readonly class DriverCompletedTrip
{
    public function __construct(
        public string $id,
        public DateTimeImmutable $scheduledAt,
        public ?DateTimeImmutable $goingStartedAt,
        public ?DateTimeImmutable $finishedAt,
        public ?string $pickupSummary,
        public ?string $destinationSummary,
        public ?int $durationSeconds,
        public float $distanceKm,
        public ?string $confirmationStatus,
        public ?bool $driverShowedUp,
    ) {}
}
