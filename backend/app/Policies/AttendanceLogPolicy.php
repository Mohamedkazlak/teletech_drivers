<?php

declare(strict_types=1);

namespace App\Policies;

use App\Domain\Enums\UserRole;
use App\Models\User;

final class AttendanceLogPolicy
{
    public function scan(User $actor): bool
    {
        return $this->isEligible($actor) && $actor->role === UserRole::Driver;
    }

    public function viewOwn(User $actor): bool
    {
        return $this->scan($actor);
    }

    public function viewAny(User $actor): bool
    {
        return $this->isStaff($actor);
    }

    public function adjust(User $actor): bool
    {
        return $this->isStaff($actor);
    }

    public function viewQr(User $actor): bool
    {
        return $this->isStaff($actor);
    }

    private function isStaff(User $actor): bool
    {
        if (! $this->isEligible($actor)) {
            return false;
        }

        return $actor->role === UserRole::Admin || $actor->role === UserRole::DriversAdmin;
    }

    private function isEligible(User $actor): bool
    {
        return $actor->is_active && $actor->deleted_at === null;
    }
}
