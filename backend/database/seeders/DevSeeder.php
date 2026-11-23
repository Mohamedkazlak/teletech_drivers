<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Application\Contracts\PasswordHasherInterface;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Domain\Repositories\PlaceRepositoryInterface;
use App\Domain\Repositories\UserRepositoryInterface;
use App\Models\DriverProfile;
use App\Models\Place;
use Illuminate\Database\Seeder;

/**
 * Local-only sample data. Never run in production.
 */
final class DevSeeder extends Seeder
{
    public function run(
        UserRepositoryInterface $users,
        PasswordHasherInterface $passwordHasher,
        PlaceRepositoryInterface $places,
    ): void {
        $passwordHash = $passwordHasher->hash((string) env('SEED_DEV_PASSWORD', 'password'));

        $this->seedUserIfMissing(
            $users,
            $passwordHash,
            'driver1@teletech.local',
            'Driver One',
            UserRole::Driver,
            Branch::CompanyHeadquarters,
        );
        $this->seedUserIfMissing(
            $users,
            $passwordHash,
            'driver2@teletech.local',
            'Driver Two',
            UserRole::Driver,
            Branch::NewHeadquarters,
        );
        $this->seedUserIfMissing(
            $users,
            $passwordHash,
            'employee1@teletech.local',
            'Employee One',
            UserRole::Employee,
            Branch::CompanyHeadquarters,
        );
        $this->seedUserIfMissing(
            $users,
            $passwordHash,
            'employee2@teletech.local',
            'Employee Two',
            UserRole::Employee,
            Branch::NewHeadquarters,
        );

        foreach (['driver1@teletech.local', 'driver2@teletech.local'] as $email) {
            $driver = $users->findByEmail($email);
            if ($driver === null) {
                continue;
            }

            DriverProfile::query()->firstOrCreate(
                ['user_id' => $driver->id],
                [
                    'national_id' => '',
                    'car_license' => '',
                    'personal_license' => '',
                ],
            );
        }

        if (! $places->activeHeadquartersExists()) {
            $places->create(
                nameEn: 'TeleTech Company Headquarters',
                nameAr: 'المقر الرئيسي',
                latitude: 30.0444,
                longitude: 31.2357,
                address: 'Cairo, Egypt',
                isHeadquarters: true,
                isActive: true,
            );
        }

        if (! Place::query()->where('name_en', 'TeleTech New Headquarters')->exists()) {
            $places->create(
                nameEn: 'TeleTech New Headquarters',
                nameAr: 'الفيلا',
                latitude: 30.0626,
                longitude: 31.2497,
                address: 'Heliopolis, Cairo',
                isHeadquarters: false,
                isActive: true,
            );
        }
    }

    private function seedUserIfMissing(
        UserRepositoryInterface $users,
        string $passwordHash,
        string $email,
        string $nameEn,
        UserRole $role,
        Branch $branch,
    ): void {
        if ($users->findByEmail($email) !== null) {
            return;
        }

        $users->createWithRole(
            nameEn: $nameEn,
            nameAr: null,
            email: $email,
            passwordHash: $passwordHash,
            role: $role,
            phone: null,
            branch: $branch,
        );
    }
}
