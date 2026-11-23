<?php

declare(strict_types=1);

namespace App\Domain\Services\TripRequest;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;

final class EmployeeCreateTripRequestStrategy implements CreateTripRequestStrategy
{
    public function build(): CreateTripRequestPlan
    {
        return new CreateTripRequestPlan(
            status: TripRequestStatus::Pending,
            autoApproved: false,
            requesterRole: UserRole::Employee,
            createTrip: false,
            setHandledBy: false,
        );
    }
}
