<?php

declare(strict_types=1);

namespace App\Domain\Services\TripRequest;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;

final class DriversAdminCreateTripRequestStrategy implements CreateTripRequestStrategy
{
    public function build(): CreateTripRequestPlan
    {
        return new CreateTripRequestPlan(
            status: TripRequestStatus::Approved,
            autoApproved: true,
            requesterRole: UserRole::DriversAdmin,
            createTrip: true,
            setHandledBy: true,
        );
    }
}
