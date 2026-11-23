<?php

declare(strict_types=1);

namespace App\Policies;

use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\User;

final class TripPolicy
{
    public function viewAny(User $actor): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return in_array($actor->role, [
            UserRole::CompanyAdmin,
            UserRole::DriversAdmin,
            UserRole::Admin,
        ], true);
    }

    public function viewMine(User $actor): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::Driver;
    }

    public function viewMyTrips(User $actor): bool
    {
        return $this->isEligibleActor($actor);
    }

    public function viewCreatedByMe(User $actor): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::DriversAdmin;
    }

    public function view(User $actor, Trip $trip): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        if (in_array($actor->role, [
            UserRole::DriversAdmin,
            UserRole::CompanyAdmin,
            UserRole::Admin,
        ], true)) {
            return true;
        }

        if ($actor->role === UserRole::Driver) {
            return $trip->driver_id === $actor->id;
        }

        return false;
    }

    public function viewSensitiveFields(User $actor, Trip $trip): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        if ($actor->role === UserRole::DriversAdmin) {
            return true;
        }

        if ($actor->role === UserRole::Driver && $trip->driver_id === $actor->id) {
            return true;
        }

        return false;
    }

    public function viewReport(User $actor, Trip $trip): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        if (in_array($actor->role, [
            UserRole::Admin,
            UserRole::DriversAdmin,
            UserRole::CompanyAdmin,
        ], true)) {
            return true;
        }

        if ($actor->role === UserRole::Driver && $trip->driver_id === $actor->id) {
            return true;
        }

        return false;
    }

    /**
     * A trip the caller is not allowed to see is hidden (404).
     * Admin, drivers admin, and company admin see every trip GET /trips lists.
     * A driver sees only the trip assigned to them.
     */
    public function reportIsOutsideScope(User $actor, Trip $trip): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        if ($actor->role === UserRole::Driver) {
            return $trip->driver_id !== $actor->id;
        }

        return false;
    }

    public function viewDriverRecommendations(User $actor, Trip $trip): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::DriversAdmin;
    }

    public function createFromRequests(User $actor): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::DriversAdmin;
    }

    public function assign(User $actor, Trip $trip): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::DriversAdmin;
    }

    public function cancel(User $actor, Trip $trip): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::DriversAdmin;
    }

    /**
     * Driver lifecycle transitions (start / arrive / start-return / end).
     */
    public function drive(User $actor, Trip $trip): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::Driver && $trip->driver_id === $actor->id;
    }

    private function isEligibleActor(User $actor): bool
    {
        return $actor->is_active && $actor->deleted_at === null;
    }
}
