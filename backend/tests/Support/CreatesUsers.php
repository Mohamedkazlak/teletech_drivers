<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Domain\Enums\UserRole;
use App\Models\DriverProfile;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

trait CreatesUsers
{
    protected ?User $actingUser = null;

    protected function actingAsRole(UserRole $role): static
    {
        $this->actingUser = $this->createUserWithRole($role);
        Sanctum::actingAs($this->actingUser);

        return $this;
    }

    protected function createUserWithRole(UserRole $role): User
    {
        $user = match ($role) {
            UserRole::Admin => User::factory()->admin()->create(),
            UserRole::CompanyAdmin => User::factory()->companyAdmin()->create(),
            UserRole::DriversAdmin => User::factory()->driversAdmin()->create(),
            UserRole::Driver => User::factory()->driver()->create(),
            UserRole::Employee => User::factory()->employee()->create(),
        };

        if ($role === UserRole::Driver) {
            DriverProfile::query()->create([
                'user_id' => $user->id,
                'national_id' => 'nid',
                'car_license' => 'car',
                'personal_license' => 'pers',
            ]);
        }

        return $user;
    }

    /**
     * @return list<UserRole>
     */
    protected function allRoles(): array
    {
        return UserRole::cases();
    }
}
