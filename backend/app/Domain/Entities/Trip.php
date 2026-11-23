<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use DateTimeImmutable;

final readonly class Trip
{
    /**
     * @param  list<TripPassenger>  $passengers
     */
    public function __construct(
        public string $id,
        public ?string $driverId,
        public DateTimeImmutable $scheduledAt,
        public TripStatus $status,
        public string $createdBy,
        public ?string $pickupSummary,
        public ?string $destinationSummary,
        public ?DateTimeImmutable $goingStartedAt,
        public ?DateTimeImmutable $goingEndedAt,
        public ?DateTimeImmutable $returnStartedAt,
        public ?DateTimeImmutable $finishedAt,
        public ?float $startLat,
        public ?float $startLng,
        public ?int $goingDistanceM,
        public ?int $returnDistanceM,
        public ?int $totalDistanceM,
        public ?string $goingRoute,
        public ?string $returnRoute,
        public DateTimeImmutable $createdAt,
        public array $passengers = [],
        public ?Driver $driver = null,
        public ?TripConfirmationStatus $confirmationStatus = null,
        public ?DateTimeImmutable $confirmationRequestedAt = null,
        public ?DateTimeImmutable $confirmedAt = null,
        public ?string $confirmedBy = null,
        public ?bool $driverShowedUp = null,
        public ?string $confirmationNote = null,
        public ?DateTimeImmutable $assignedAt = null,
        /** @var array<string, RequestTracking> */
        public array $trackingByEmployeeId = [],
    ) {}

    /**
     * Only definition of passenger_count.
     *
     * Each linked request contributes its passenger row. A grouped trip
     * (several requests on one trip) is the sum of those rows.
     */
    public function passengerCount(): int
    {
        return count($this->passengers);
    }
}
