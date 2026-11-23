<?php

declare(strict_types=1);

namespace App\Domain\Services\TripRequest;

use App\Domain\Enums\UserRole;
use DomainException;

/**
 * Factory: picks the create-request Strategy for the signed-in role.
 */
final class CreateTripRequestStrategyFactory
{
    public function forRole(UserRole $role): CreateTripRequestStrategy
    {
        return match ($role) {
            UserRole::Employee => new EmployeeCreateTripRequestStrategy,
            UserRole::CompanyAdmin => new CompanyAdminCreateTripRequestStrategy,
            UserRole::DriversAdmin => new DriversAdminCreateTripRequestStrategy,
            UserRole::Admin => new AdminCreateTripRequestStrategy,
            UserRole::Driver => throw new DomainException('Drivers cannot create trip requests.'),
        };
    }
}
