<?php

declare(strict_types=1);

namespace App\Domain\Specifications;

use App\Domain\Entities\Driver;
use App\Domain\Enums\AvailabilityStatus;

/**
 * Specification: active driver with official availability = available.
 */
final class AvailableDriverSpecification
{
    public function isSatisfiedBy(Driver $driver): bool
    {
        $user = $driver->user;

        return $user->isActive
            && $user->deletedAt === null
            && $user->availabilityStatus === AvailabilityStatus::Available;
    }
}
