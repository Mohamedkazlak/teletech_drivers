<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Application\Contracts\PasswordHasherInterface;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Domain\Repositories\PlaceRepositoryInterface;
use App\Models\User;
use Illuminate\Console\Command;

/**
 * Upserts fixed local accounts and ensures one headquarters place in Cairo.
 * Refuses every environment other than local and testing.
 */
final class SeedDevUsersCommand extends Command
{
    private const PASSWORD = 'test123456';

    private const CAIRO_LATITUDE = 30.0444;

    private const CAIRO_LONGITUDE = 31.2357;

    protected $signature = 'dev:seed-users';

    protected $description = 'Upsert local test accounts and a Cairo headquarters place';

    public function handle(
        PasswordHasherInterface $passwordHasher,
        PlaceRepositoryInterface $places,
    ): int {
        if (! app()->environment(['local', 'testing'])) {
            $this->error('Refused: dev:seed-users runs only when APP_ENV is local or testing.');

            return self::FAILURE;
        }

        $passwordHash = $passwordHasher->hash(self::PASSWORD);
        $rows = [];

        foreach ($this->accounts() as $account) {
            $this->upsert($account, $passwordHash);
            $rows[] = [
                $account['email'],
                $account['role']->value,
                $account['branch']?->value ?? '-',
                $account['name_en'],
                $account['name_ar'],
                self::PASSWORD,
            ];
        }

        if ($places->activeHeadquartersExists()) {
            $this->info('Headquarters place already exists.');
        } else {
            $places->create(
                nameEn: 'Cairo Headquarters',
                nameAr: 'مقر القاهرة',
                latitude: self::CAIRO_LATITUDE,
                longitude: self::CAIRO_LONGITUDE,
                address: 'Cairo, Egypt',
                isHeadquarters: true,
                isActive: true,
            );
            $this->info('Headquarters place created at Cairo (30.0444, 31.2357).');
        }

        $this->info('Upserted local accounts. Password for every account is '.self::PASSWORD.'.');
        $this->table(
            ['Email', 'Role', 'Branch', 'Name (EN)', 'Name (AR)', 'Password'],
            $rows,
        );

        return self::SUCCESS;
    }

    /**
     * @param  array{email: string, role: UserRole, branch: Branch|null, name_en: string, name_ar: string}  $account
     */
    private function upsert(array $account, string $passwordHash): void
    {
        $user = User::withTrashed()->where('email', $account['email'])->first();
        if ($user === null) {
            $user = new User;
        } elseif ($user->trashed()) {
            $user->restore();
        }

        $user->forceFill([
            'name_en' => $account['name_en'],
            'name_ar' => $account['name_ar'],
            'email' => $account['email'],
            'password' => $passwordHash,
            'role' => $account['role'],
            'is_active' => true,
            'branch' => $account['branch'],
            'must_change_password' => false,
        ]);
        $user->save();
    }

    /**
     * @return list<array{email: string, role: UserRole, branch: Branch|null, name_en: string, name_ar: string}>
     */
    private function accounts(): array
    {
        return [
            [
                'email' => 'admin@test.com',
                'role' => UserRole::Admin,
                'branch' => null,
                'name_en' => 'Test Admin',
                'name_ar' => 'مدير النظام',
            ],
            [
                'email' => 'companyadmin@test.com',
                'role' => UserRole::CompanyAdmin,
                'branch' => null,
                'name_en' => 'Test Company Admin',
                'name_ar' => 'مدير الشركة',
            ],
            [
                'email' => 'driversadmin@test.com',
                'role' => UserRole::DriversAdmin,
                'branch' => null,
                'name_en' => 'Test Drivers Admin',
                'name_ar' => 'مسؤول السائقين',
            ],
            [
                'email' => 'driver@test.com',
                'role' => UserRole::Driver,
                'branch' => Branch::CompanyHeadquarters,
                'name_en' => 'Test Driver',
                'name_ar' => 'سائق الاختبار',
            ],
            [
                'email' => 'employee@test.com',
                'role' => UserRole::Employee,
                'branch' => Branch::NewHeadquarters,
                'name_en' => 'Test Employee',
                'name_ar' => 'موظف الاختبار',
            ],
        ];
    }
}
