<?php

declare(strict_types=1);

namespace App\Policies;

use App\Domain\Enums\UserRole;
use App\Models\User;

final class UserPolicy
{
    public function viewAnyDrivers(User $actor): bool
    {
        return in_array($actor->role, [
            UserRole::Admin,
            UserRole::DriversAdmin,
            UserRole::CompanyAdmin,
        ], true);
    }

    public function viewDriver(User $actor, User $driver): bool
    {
        if ($driver->role !== UserRole::Driver) {
            return false;
        }

        return $this->viewAnyDrivers($actor);
    }

    public function viewPrivateDriverFields(User $actor, User $driver): bool
    {
        if ($driver->role !== UserRole::Driver) {
            return false;
        }

        if ($actor->id === $driver->id && $actor->role === UserRole::Driver) {
            return true;
        }

        return in_array($actor->role, [
            UserRole::Admin,
            UserRole::DriversAdmin,
        ], true);
    }

    public function viewOwnDriverProfile(User $actor): bool
    {
        return $actor->role === UserRole::Driver;
    }

    public function viewOwnStats(User $actor): bool
    {
        return $actor->role === UserRole::Driver;
    }

    public function exportMovementReport(User $actor, User $driver): bool
    {
        if ($driver->role !== UserRole::Driver || $driver->deleted_at !== null) {
            return false;
        }

        return in_array($actor->role, [
            UserRole::Admin,
            UserRole::CompanyAdmin,
            UserRole::DriversAdmin,
        ], true);
    }

    public function viewDriverActivity(User $actor, User $driver): bool
    {
        if ($driver->role !== UserRole::Driver) {
            return false;
        }

        return in_array($actor->role, [
            UserRole::Admin,
            UserRole::DriversAdmin,
        ], true);
    }

    public function createDriver(User $actor): bool
    {
        return in_array($actor->role, [
            UserRole::Admin,
            UserRole::DriversAdmin,
        ], true);
    }

    public function updateDriver(User $actor, User $driver): bool
    {
        if ($driver->role !== UserRole::Driver) {
            return false;
        }

        if ($actor->id === $driver->id) {
            return false;
        }

        return $this->createDriver($actor);
    }

    public function deleteDriver(User $actor, User $driver): bool
    {
        return $this->updateDriver($actor, $driver);
    }

    public function restoreDriver(User $actor, User $driver): bool
    {
        return $this->updateDriver($actor, $driver);
    }

    public function viewAnyEmployees(User $actor): bool
    {
        return in_array($actor->role, [
            UserRole::Admin,
            UserRole::CompanyAdmin,
        ], true);
    }

    public function viewEmployee(User $actor, User $employee): bool
    {
        if ($employee->role !== UserRole::Employee) {
            return false;
        }

        return $this->viewAnyEmployees($actor);
    }

    public function createEmployee(User $actor): bool
    {
        return $actor->role === UserRole::Admin;
    }

    public function updateEmployee(User $actor, User $employee): bool
    {
        if ($employee->role !== UserRole::Employee) {
            return false;
        }

        if ($actor->id === $employee->id) {
            return false;
        }

        return $actor->role === UserRole::Admin;
    }

    public function deleteEmployee(User $actor, User $employee): bool
    {
        return $this->updateEmployee($actor, $employee);
    }

    public function restoreEmployee(User $actor, User $employee): bool
    {
        return $this->updateEmployee($actor, $employee);
    }

    public function viewAdminDashboard(User $actor): bool
    {
        return $actor->role === UserRole::Admin;
    }

    public function viewAnyUsers(User $actor): bool
    {
        return $actor->role === UserRole::Admin;
    }

    public function resetPassword(User $actor, User $target): bool
    {
        return $actor->role === UserRole::Admin;
    }
}
