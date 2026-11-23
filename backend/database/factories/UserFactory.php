<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

/**
 * @extends Factory<User>
 */
final class UserFactory extends Factory
{
    protected static ?string $password = null;

    protected $model = User::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name_en' => fake()->name(),
            'name_ar' => null,
            'email' => fake()->unique()->safeEmail(),
            'password' => self::$password ??= Hash::make('password'),
            'role' => UserRole::Employee,
            'is_active' => true,
            'phone' => fake()->optional()->numerify('01#########'),
            'branch' => Branch::CompanyHeadquarters,
            'must_change_password' => false,
            'deleted_by' => null,
        ];
    }

    public function admin(): static
    {
        return $this->state(fn (): array => ['role' => UserRole::Admin]);
    }

    public function companyAdmin(): static
    {
        return $this->state(fn (): array => ['role' => UserRole::CompanyAdmin]);
    }

    public function driversAdmin(): static
    {
        return $this->state(fn (): array => ['role' => UserRole::DriversAdmin]);
    }

    public function driver(): static
    {
        return $this->state(fn (): array => ['role' => UserRole::Driver]);
    }

    public function employee(): static
    {
        return $this->state(fn (): array => ['role' => UserRole::Employee]);
    }

    public function inactive(): static
    {
        return $this->state(fn (): array => ['is_active' => false]);
    }
}
