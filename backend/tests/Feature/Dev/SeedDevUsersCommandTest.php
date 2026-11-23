<?php

declare(strict_types=1);

namespace Tests\Feature\Dev;

use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Models\Place;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

final class SeedDevUsersCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_upserts_accounts_and_creates_a_cairo_headquarters(): void
    {
        $this->artisan('dev:seed-users')
            ->expectsOutputToContain('admin@test.com')
            ->expectsOutputToContain('test123456')
            ->expectsOutputToContain('Headquarters place created at Cairo (30.0444, 31.2357).')
            ->assertSuccessful();

        $this->artisan('dev:seed-users')->assertSuccessful();

        $this->assertSame(5, User::query()->count());
        $this->assertSame(1, Place::query()->where('is_headquarters', true)->count());

        $expected = [
            'admin@test.com' => [UserRole::Admin, null, 'Test Admin', 'مدير النظام'],
            'companyadmin@test.com' => [UserRole::CompanyAdmin, null, 'Test Company Admin', 'مدير الشركة'],
            'driversadmin@test.com' => [UserRole::DriversAdmin, null, 'Test Drivers Admin', 'مسؤول السائقين'],
            'driver@test.com' => [UserRole::Driver, Branch::CompanyHeadquarters, 'Test Driver', 'سائق الاختبار'],
            'employee@test.com' => [UserRole::Employee, Branch::NewHeadquarters, 'Test Employee', 'موظف الاختبار'],
        ];

        foreach ($expected as $email => [$role, $branch, $nameEn, $nameAr]) {
            $user = User::query()->where('email', $email)->firstOrFail();
            $this->assertSame($role, $user->role);
            $this->assertSame($branch, $user->branch);
            $this->assertSame($nameEn, $user->name_en);
            $this->assertSame($nameAr, $user->name_ar);
            $this->assertTrue($user->is_active);
            $this->assertFalse($user->must_change_password);
            $this->assertTrue(Hash::check('test123456', $user->password));
        }

        foreach (['admin@test.com', 'driver@test.com', 'employee@test.com'] as $email) {
            $login = $this->postJson('/api/auth/login', [
                'email' => $email,
                'password' => 'test123456',
            ])->assertOk()->assertJsonPath('user.must_change_password', false);

            $this->withToken((string) $login->json('token'))
                ->getJson('/api/places')
                ->assertOk();
        }

        $headquarters = Place::query()->where('is_headquarters', true)->firstOrFail();
        $this->assertSame('Cairo Headquarters', $headquarters->name_en);
        $this->assertSame('مقر القاهرة', $headquarters->name_ar);
        $this->assertSame('Cairo, Egypt', $headquarters->address);
        $this->assertTrue($headquarters->is_active);
        $this->assertEqualsWithDelta(30.0444, (float) $headquarters->latitude, 0.0000001);
        $this->assertEqualsWithDelta(31.2357, (float) $headquarters->longitude, 0.0000001);
    }

    public function test_updates_existing_accounts_and_keeps_an_existing_headquarters(): void
    {
        Place::factory()->headquarters()->create([
            'name_en' => 'Existing HQ',
            'name_ar' => 'مقر قائم',
            'latitude' => 29.9,
            'longitude' => 31.1,
            'address' => 'Giza',
        ]);

        $admin = User::factory()->employee()->create([
            'email' => 'admin@test.com',
            'name_en' => 'Wrong',
            'name_ar' => 'خطأ',
            'is_active' => false,
            'must_change_password' => true,
            'branch' => Branch::NewHeadquarters,
            'password' => Hash::make('old-password'),
        ]);
        $admin->delete();

        $this->artisan('dev:seed-users')
            ->expectsOutputToContain('Headquarters place already exists.')
            ->assertSuccessful();

        $this->assertSame(1, Place::query()->where('is_headquarters', true)->count());
        $headquarters = Place::query()->where('is_headquarters', true)->firstOrFail();
        $this->assertSame('Existing HQ', $headquarters->name_en);
        $this->assertEqualsWithDelta(29.9, (float) $headquarters->latitude, 0.0000001);
        $this->assertEqualsWithDelta(31.1, (float) $headquarters->longitude, 0.0000001);

        $updated = User::query()->where('email', 'admin@test.com')->firstOrFail();
        $this->assertNull($updated->deleted_at);
        $this->assertSame(UserRole::Admin, $updated->role);
        $this->assertNull($updated->branch);
        $this->assertTrue($updated->is_active);
        $this->assertFalse($updated->must_change_password);
        $this->assertSame('Test Admin', $updated->name_en);
        $this->assertSame('مدير النظام', $updated->name_ar);
        $this->assertTrue(Hash::check('test123456', $updated->password));
        $this->assertFalse(Hash::check('old-password', $updated->password));
        $this->assertSame(5, User::query()->count());
    }

    public function test_refuses_when_the_environment_is_not_local_or_testing(): void
    {
        foreach (['production', 'staging'] as $environment) {
            $this->app->instance('env', $environment);

            $this->artisan('dev:seed-users')
                ->expectsOutputToContain('Refused: dev:seed-users runs only when APP_ENV is local or testing.')
                ->assertFailed();
        }

        $this->assertSame(0, User::query()->count());
        $this->assertSame(0, Place::query()->count());
    }
}
