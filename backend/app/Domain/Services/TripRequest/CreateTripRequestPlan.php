<?php

declare(strict_types=1);

namespace App\Domain\Services\TripRequest;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;

/**
 * Values a create-request Strategy chooses before persistence.
 */
final readonly class CreateTripRequestPlan
{
    public function __construct(
        public TripRequestStatus $status,
        public bool $autoApproved,
        public UserRole $requesterRole,
        public bool $createTrip,
        public bool $setHandledBy,
    ) {}
}
