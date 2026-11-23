<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Application\Contracts\PasswordHasherInterface;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Domain\Repositories\UserRepositoryInterface;
use Illuminate\Database\Seeder;
use RuntimeException;

final class DatabaseSeeder extends Seeder
{
    public function run(UserRepositoryInterface $users, PasswordHasherInterface $passwordHasher): void
    {
        $this->seedRole(
            users: $users,
            passwordHasher: $passwordHasher,
            role: UserRole::Admin,
            emailEnv: 'SEED_ADMIN_EMAIL',
            passwordEnv: 'SEED_ADMIN_PASSWORD',
            nameEn: 'System Admin',
        );

        $this->seedRole(
            users: $users,
            passwordHasher: $passwordHasher,
            role: UserRole::CompanyAdmin,
            emailEnv: 'SEED_COMPANY_ADMIN_EMAIL',
            passwordEnv: 'SEED_COMPANY_ADMIN_PASSWORD',
            nameEn: 'Company Admin',
        );

        $this->seedRole(
            users: $users,
            passwordHasher: $passwordHasher,
            role: UserRole::DriversAdmin,
            emailEnv: 'SEED_DRIVERS_ADMIN_EMAIL',
            passwordEnv: 'SEED_DRIVERS_ADMIN_PASSWORD',
            nameEn: 'Drivers Admin',
        );

        if (app()->environment('local')) {
            $this->call(DevSeeder::class);
        }
    }

    private function seedRole(
        UserRepositoryInterface $users,
        PasswordHasherInterface $passwordHasher,
        UserRole $role,
        string $emailEnv,
        string $passwordEnv,
        string $nameEn,
    ): void {
        $email = env($emailEnv);
        $password = env($passwordEnv);

        if (! is_string($email) || $email === '' || ! is_string($password) || $password === '') {
            throw new RuntimeException("Missing required env vars {$emailEnv} / {$passwordEnv}.");
        }

        if ($users->findByEmail($email) !== null) {
            return;
        }

        $users->createWithRole(
            nameEn: $nameEn,
            nameAr: null,
            email: $email,
            passwordHash: $passwordHasher->hash($password),
            role: $role,
            phone: null,
            branch: Branch::CompanyHeadquarters,
        );
    }
}
