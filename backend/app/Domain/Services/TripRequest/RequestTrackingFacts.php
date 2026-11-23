<?php

declare(strict_types=1);

namespace App\Domain\Services\TripRequest;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use DateTimeImmutable;

/**
 * Inputs for {@see RequestTrackingService}. No other passenger and no notes.
 */
final readonly class RequestTrackingFacts
{
    public function __construct(
        public TripRequestStatus $requestStatus,
        public UserRole $requesterRole,
        public bool $autoApproved,
        public DateTimeImmutable $createdAt,
        public ?DateTimeImmutable $approvedAt,
        public ?DateTimeImmutable $handledAt,
        public ?string $rejectionReason,
        public ?DateTimeImmutable $requestUpdatedAt,
        public ?TripStatus $tripStatus,
        public ?DateTimeImmutable $scheduledAt,
        public ?DateTimeImmutable $assignedAt,
        public ?DateTimeImmutable $goingStartedAt,
        public ?DateTimeImmutable $finishedAt,
        public ?TripConfirmationStatus $confirmationStatus,
        public ?DateTimeImmutable $confirmationRequestedAt,
        public ?DateTimeImmutable $confirmedAt,
        public ?UserRole $confirmationActorRole,
        public ?DateTimeImmutable $tripUpdatedAt,
        public bool $hasDriver,
        public ?string $driverNameEn,
        public ?string $driverNameAr,
        public ?string $driverPhone,
        public ?string $carLicense,
    ) {}
}
