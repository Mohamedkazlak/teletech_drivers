<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use DateTimeImmutable;

final readonly class TripRequest
{
    public function __construct(
        public string $id,
        public string $employeeId,
        public UserRole $requesterRole,
        public PlaceSnapshot $pickup,
        public PlaceSnapshot $destination,
        public DateTimeImmutable $requestedAt,
        public string $notes,
        public TripRequestStatus $status,
        public ?string $tripId,
        public ?string $rejectionReason,
        public ?string $handledBy,
        public ?DateTimeImmutable $handledAt,
        public bool $autoApproved,
        public ?string $suggestedGroupId,
        public DateTimeImmutable $createdAt,
        public ?string $employeeNameEn = null,
        public ?string $employeeNameAr = null,
        public ?string $employeePhone = null,
        public ?string $employeeBranch = null,
        public ?TripStatus $tripStatus = null,
        public ?LinkedTrip $linkedTrip = null,
        public ?DateTimeImmutable $approvedAt = null,
        public ?RequestTracking $tracking = null,
    ) {}

    public function isAwaitingTrip(): bool
    {
        return $this->status === TripRequestStatus::Approved && $this->tripId === null;
    }

    public function canCancel(): bool
    {
        return $this->status === TripRequestStatus::Pending || $this->isAwaitingTrip();
    }
}
