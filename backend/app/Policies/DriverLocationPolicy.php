<?php

declare(strict_types=1);

namespace App\Policies;

use App\Domain\Enums\UserRole;
use App\Models\DriverLocation;
use App\Models\User;

final class DriverLocationPolicy
{
    public function publish(User $actor): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::Driver;
    }

    public function stop(User $actor): bool
    {
        return $this->publish($actor);
    }

    public function viewLiveMap(User $actor): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::Admin
            || $actor->role === UserRole::DriversAdmin;
    }

    public function update(User $actor, DriverLocation $driverLocation): bool
    {
        if (! $this->isEligibleActor($actor)) {
            return false;
        }

        return $actor->role === UserRole::Driver && $driverLocation->driver_id === $actor->id;
    }

    private function isEligibleActor(User $actor): bool
    {
        return $actor->is_active && $actor->deleted_at === null;
    }
}
