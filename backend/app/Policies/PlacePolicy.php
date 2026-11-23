<?php

declare(strict_types=1);

namespace App\Policies;

use App\Domain\Enums\UserRole;
use App\Models\Place;
use App\Models\User;

final class PlacePolicy
{
    public function viewAny(User $actor): bool
    {
        return true;
    }

    public function view(User $actor, Place $place): bool
    {
        return true;
    }

    public function create(User $actor): bool
    {
        return $this->canManage($actor);
    }

    public function update(User $actor, Place $place): bool
    {
        return $this->canManage($actor);
    }

    public function delete(User $actor, Place $place): bool
    {
        return $this->canManage($actor);
    }

    private function canManage(User $actor): bool
    {
        return in_array($actor->role, [
            UserRole::Admin,
            UserRole::CompanyAdmin,
            UserRole::DriversAdmin,
        ], true);
    }
}
