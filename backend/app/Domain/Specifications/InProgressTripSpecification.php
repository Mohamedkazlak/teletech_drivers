<?php

declare(strict_types=1);

namespace App\Domain\Specifications;

use App\Domain\Enums\TripStatus;

/**
 * Specification: trip is going / at_destination / returning (Flutter isInProgress).
 */
final class InProgressTripSpecification
{
    public function isSatisfiedBy(TripStatus $status): bool
    {
        return $status === TripStatus::Going
            || $status === TripStatus::AtDestination
            || $status === TripStatus::Returning;
    }
}
