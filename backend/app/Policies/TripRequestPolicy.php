<?php

declare(strict_types=1);

namespace App\Policies;

use App\Domain\Enums\UserRole;
use App\Models\TripRequest;
use App\Models\User;

final class TripRequestPolicy
{
    public function viewAny(User $actor): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return in_array($actor->role, [
            UserRole::Admin,
            UserRole::CompanyAdmin,
            UserRole::DriversAdmin,
        ], true);
    }

    public function viewMine(User $actor): bool
    {
        return $this->isEligibleActor($actor);
    }

    public function view(User $actor, TripRequest $tripRequest): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        if ($actor->id === $tripRequest->employee_id) {
            return true;
        }

        if (in_array($actor->role, [UserRole::CompanyAdmin, UserRole::DriversAdmin], true)) {
            return true;
        }

        if ($actor->role === UserRole::Driver && $tripRequest->trip_id !== null) {
            $trip = $tripRequest->trip()->first();

            return $trip !== null && $trip->driver_id === $actor->id;
        }

        return false;
    }

    public function create(User $actor): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return in_array($actor->role, [
            UserRole::Employee,
            UserRole::CompanyAdmin,
            UserRole::Admin,
            UserRole::DriversAdmin,
        ], true);
    }

    public function cancel(User $actor, TripRequest $tripRequest): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->id === $tripRequest->employee_id;
    }

    /**
     * Ownership, not role alone: the requester is trip_requests.employee_id.
     * Only an employee, company admin, or drivers admin may file that report.
     */
    public function confirm(User $actor, TripRequest $tripRequest): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        if ($actor->id !== $tripRequest->employee_id) {
            return false;
        }

        return in_array($actor->role, [
            UserRole::Employee,
            UserRole::CompanyAdmin,
            UserRole::DriversAdmin,
        ], true);
    }

    public function approve(User $actor, TripRequest $tripRequest): bool
    {
        return $this->isCompanyAdmin($actor);
    }

    public function reject(User $actor, TripRequest $tripRequest): bool
    {
        return $this->isCompanyAdmin($actor);
    }

    public function approveGroup(User $actor): bool
    {
        return $this->isCompanyAdmin($actor);
    }

    public function viewGroupingSuggestions(User $actor): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return in_array($actor->role, [
            UserRole::CompanyAdmin,
            UserRole::DriversAdmin,
        ], true);
    }

    private function isCompanyAdmin(User $actor): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::CompanyAdmin;
    }

    private function isEligibleActor(User $actor): bool
    {
        return $actor->is_active && $actor->deleted_at === null;
    }
}
