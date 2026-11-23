<?php

declare(strict_types=1);

namespace App\Domain\Services\TripRequest;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;

final class AdminCreateTripRequestStrategy implements CreateTripRequestStrategy
{
    public function build(): CreateTripRequestPlan
    {
        return new CreateTripRequestPlan(
            status: TripRequestStatus::Approved,
            autoApproved: true,
            requesterRole: UserRole::Admin,
            createTrip: false,
            setHandledBy: true,
        );
    }
}
