<?php

declare(strict_types=1);

namespace Tests\Feature\Drivers;

use App\Domain\Enums\UserRole;
use App\Models\DriverProfile;
use App\Models\Place;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class DriverEndpointsTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    /**
     * @return array{name_en: string, name_ar: string, email: string, password: string, phone: string, national_id: string, car_license: string, personal_license: string, favorite_place_ids: list<string>}
     */
    private function driverPayload(string $email = 'newdriver@example.com', array $favoritePlaceIds = []): array
    {
        return [
            'name_en' => 'New Driver',
            'name_ar' => 'سائق جديد',
            'email' => $email,
            'password' => 'password123',
            'phone' => '01011112222',
            'national_id' => 'ACCT-000028',
            'car_license' => 'ط ع ب 9295',
            'personal_license' => 'PERS-1',
            'favorite_place_ids' => $favoritePlaceIds,
        ];
    }

    private function createDriverUser(): User
    {
        $driver = User::factory()->driver()->create();
        DriverProfile::query()->create([
            'user_id' => $driver->id,
            'national_id' => 'secret-nid',
            'car_license' => 'secret-car',
            'personal_license' => 'secret-pers',
        ]);

        return $driver;
    }

    public function test_unauthenticated_returns_401(): void
    {
        $this->getJson('/api/drivers')->assertUnauthorized();
        $this->postJson('/api/drivers', [])->assertUnauthorized();
    }

    /**
     * @return list<array{0: UserRole, 1: int}>
     */
    public static function listRoleMatrix(): array
    {
        return [
            [UserRole::Admin, 200],
            [UserRole::DriversAdmin, 200],
            [UserRole::CompanyAdmin, 200],
            [UserRole::Driver, 403],
            [UserRole::Employee, 403],
        ];
    }

    #[DataProvider('listRoleMatrix')]
    public function test_list_drivers_role_matrix(UserRole $role, int $status): void
    {
        $this->createDriverUser();

        $this->actingAsRole($role)
            ->getJson('/api/drivers')
            ->assertStatus($status);
    }

    /**
     * @return list<array{0: UserRole, 1: int}>
     */
    public static function writeRoleMatrix(): array
    {
        return [
            [UserRole::Admin, 201],
            [UserRole::DriversAdmin, 201],
            [UserRole::CompanyAdmin, 403],
            [UserRole::Driver, 403],
            [UserRole::Employee, 403],
        ];
    }

    #[DataProvider('writeRoleMatrix')]
    public function test_create_driver_role_matrix(UserRole $role, int $status): void
    {
        $place = Place::factory()->create();

        $this->actingAsRole($role)
            ->postJson('/api/drivers', $this->driverPayload(
                email: 'role-'.$role->value.'@example.com',
                favoritePlaceIds: [$place->id],
            ))
            ->assertStatus($status);
    }

    public function test_company_admin_cannot_see_private_fields(): void
    {
        $driver = $this->createDriverUser();

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->getJson('/api/drivers/'.$driver->id)
            ->assertOk()
            ->assertJsonMissingPath('national_id')
            ->assertJsonMissingPath('car_license')
            ->assertJsonMissingPath('personal_license')
            ->assertJsonPath('email', $driver->email);
    }

    public function test_admin_sees_private_fields(): void
    {
        $driver = $this->createDriverUser();

        $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/drivers/'.$driver->id)
            ->assertOk()
            ->assertJsonPath('national_id', 'secret-nid')
            ->assertJsonPath('car_license', 'secret-car');
    }

    public function test_driver_can_read_own_profile_via_auth_endpoint(): void
    {
        $this->actingAsRole(UserRole::Driver);

        $this->getJson('/api/auth/me/driver-profile')
            ->assertOk()
            ->assertJsonPath('id', $this->actingUser?->id)
            ->assertJsonPath('national_id', 'nid');
    }

    public function test_employee_cannot_access_own_driver_profile_endpoint(): void
    {
        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/auth/me/driver-profile')
            ->assertForbidden();
    }

    public function test_cannot_act_on_self(): void
    {
        $admin = User::factory()->driversAdmin()->create();
        // promote to also be treatable? cannot act on self means drivers_admin deleting themselves
        // Spec: Cannot act on self for create/update/soft-delete/restore of drivers.
        // So a drivers_admin who is somehow a driver target - typically admin acting on own user id if they were a driver.
        // Test: drivers_admin tries to update/delete their own user id even though role isn't driver -> 404
        // Better: create a drivers_admin, and also test update on same id when role is drivers_admin targeting another.
        // The self-check is in policy for driver targets. Create a user that is a driver and act as that driver trying to update self via drivers API.

        $driver = $this->createDriverUser();
        $this->actingAs($driver, 'sanctum')
            ->patchJson('/api/drivers/'.$driver->id, [
                'name_en' => 'Hack',
                'name_ar' => 'هـ',
                'national_id' => 'x',
                'car_license' => 'ط ع ب 9295',
                'personal_license' => 'x',
                'favorite_place_ids' => [],
                'is_active' => true,
            ])
            ->assertForbidden();
    }

    public function test_soft_delete_revokes_tokens_and_blocks_login(): void
    {
        $driver = $this->createDriverUser();
        $token = $driver->createToken('auth');
        $plain = $token->plainTextToken;
        $tokenId = $token->accessToken->id;

        $this->actingAsRole(UserRole::Admin)
            ->deleteJson('/api/drivers/'.$driver->id)
            ->assertOk()
            ->assertJsonPath('is_active', false);

        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $tokenId]);
        $this->assertSoftDeleted('users', ['id' => $driver->id]);

        $this->app['auth']->forgetGuards();

        $this->withToken($plain)
            ->getJson('/api/auth/me')
            ->assertUnauthorized();

        $this->postJson('/api/auth/login', [
            'email' => $driver->email,
            'password' => 'password',
        ])->assertUnauthorized();
    }

    public function test_restore_reactivates_driver(): void
    {
        $driver = $this->createDriverUser();

        $this->actingAsRole(UserRole::Admin)
            ->deleteJson('/api/drivers/'.$driver->id)
            ->assertOk();

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/drivers/'.$driver->id.'/restore')
            ->assertOk()
            ->assertJsonPath('is_active', true)
            ->assertJsonPath('deleted_at', null);
    }

    public function test_duplicate_email_returns_422(): void
    {
        $existing = $this->createDriverUser();
        $place = Place::factory()->create();

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/drivers', $this->driverPayload(
                email: $existing->email,
                favoritePlaceIds: [$place->id],
            ))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_invalid_favorite_place_returns_422(): void
    {
        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/drivers', $this->driverPayload(
                favoritePlaceIds: ['00000000-0000-0000-0000-000000000099'],
            ))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['favorite_place_ids.0']);
    }

    public function test_inactive_favorite_place_returns_422(): void
    {
        $place = Place::factory()->inactive()->create();

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/drivers', $this->driverPayload(
                favoritePlaceIds: [$place->id],
            ))
            ->assertStatus(422);
    }

    public function test_failed_profile_creation_leaves_no_orphan_user(): void
    {
        $place = Place::factory()->create();

        DriverProfile::creating(function (): void {
            throw new \RuntimeException('Simulated profile failure');
        });

        try {
            $this->actingAsRole(UserRole::Admin)
                ->postJson('/api/drivers', $this->driverPayload(
                    email: 'orphan@example.com',
                    favoritePlaceIds: [$place->id],
                ))
                ->assertStatus(500);
        } catch (\RuntimeException $e) {
            $this->assertSame('Simulated profile failure', $e->getMessage());
        }

        $this->assertDatabaseMissing('users', ['email' => 'orphan@example.com']);
        $this->assertSame(0, DB::table('driver_profiles')->count());
    }

    public function test_email_and_role_immutable_on_update(): void
    {
        $driver = $this->createDriverUser();
        $place = Place::factory()->create();

        $this->actingAsRole(UserRole::Admin)
            ->patchJson('/api/drivers/'.$driver->id, [
                'name_en' => 'Updated Driver',
                'name_ar' => 'محدث',
                'phone' => '01511112222',
                'national_id' => 'nid2',
                'car_license' => 'ب 12',
                'personal_license' => 'pers2',
                'favorite_place_ids' => [$place->id],
                'is_active' => true,
                'email' => 'hacked@example.com',
                'role' => 'admin',
            ])
            ->assertOk()
            ->assertJsonPath('email', $driver->email)
            ->assertJsonPath('role', UserRole::Driver->value)
            ->assertJsonPath('name_en', 'Updated Driver');
    }

    public function test_create_driver_syncs_favorites(): void
    {
        $place = Place::factory()->create();

        $response = $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/drivers', $this->driverPayload(favoritePlaceIds: [$place->id]))
            ->assertCreated();

        $id = $response->json('id');
        $this->assertTrue(User::query()->findOrFail($id)->must_change_password);
        $this->assertDatabaseHas('driver_favorite_places', [
            'user_id' => $id,
            'place_id' => $place->id,
        ]);
        $this->assertDatabaseHas('driver_profiles', ['user_id' => $id]);
    }

    public function test_driver_resources_expose_derived_availability_without_changing_visibility(): void
    {
        $driver = $this->createDriverUser();

        $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/drivers/'.$driver->id)
            ->assertOk()
            ->assertJsonPath('is_available', false)
            ->assertJsonMissingPath('availability_status')
            ->assertJsonPath('national_id', 'secret-nid');

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->getJson('/api/drivers/'.$driver->id)
            ->assertOk()
            ->assertJsonPath('is_available', false)
            ->assertJsonMissingPath('national_id')
            ->assertJsonMissingPath('car_license')
            ->assertJsonMissingPath('personal_license');

        $this->actingAsRole(UserRole::DriversAdmin)
            ->getJson('/api/drivers/'.$driver->id)
            ->assertOk()
            ->assertJsonPath('is_available', false)
            ->assertJsonPath('national_id', 'secret-nid');

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->getJson('/api/drivers/'.$driver->id)
            ->assertOk()
            ->assertJsonPath('is_available', false)
            ->assertJsonMissingPath('national_id');

        $this->actingAsRole(UserRole::Driver);

        $this->getJson('/api/auth/me/driver-profile')
            ->assertOk()
            ->assertJsonPath('is_available', false)
            ->assertJsonPath('national_id', 'nid');

        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/auth/me/driver-profile')
            ->assertForbidden();

        $this->actingAsRole(UserRole::Driver)
            ->getJson('/api/drivers/'.$driver->id)
            ->assertForbidden();
    }

    public function test_favorite_places_are_limited_to_five(): void
    {
        $ids = [];
        for ($i = 0; $i < 6; $i++) {
            $ids[] = Place::factory()->create()->id;
        }

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/drivers', $this->driverPayload(
                email: 'too-many@example.com',
                favoritePlaceIds: $ids,
            ))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['favorite_place_ids']);

        $driver = $this->createDriverUser();
        $five = array_slice($ids, 0, 5);

        $this->actingAsRole(UserRole::Admin)
            ->patchJson('/api/drivers/'.$driver->id, [
                'name_en' => 'Updated Driver',
                'name_ar' => 'محدث',
                'phone' => '01511112222',
                'national_id' => 'nid2',
                'car_license' => 'ب 12',
                'personal_license' => 'pers2',
                'favorite_place_ids' => $ids,
                'is_active' => true,
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['favorite_place_ids']);

        $this->actingAsRole(UserRole::Admin)
            ->patchJson('/api/drivers/'.$driver->id, [
                'name_en' => 'Updated Driver',
                'name_ar' => 'محدث',
                'phone' => '01511112222',
                'national_id' => 'nid2',
                'car_license' => 'ب 12',
                'personal_license' => 'pers2',
                'favorite_place_ids' => $five,
                'is_active' => true,
            ])
            ->assertOk()
            ->assertJsonCount(5, 'favorite_place_ids');
    }

    public function test_create_requires_phone_and_stores_a_canonical_plate(): void
    {
        $missingPhone = $this->driverPayload(email: 'nophone@example.com');
        unset($missingPhone['phone']);

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/drivers', $missingPhone)
            ->assertStatus(422)
            ->assertJsonValidationErrors(['phone']);

        $invalidPlate = $this->driverPayload(email: 'badplate@example.com');
        $invalidPlate['car_license'] = 'CAR-1';

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/drivers', $invalidPlate)
            ->assertStatus(422)
            ->assertJsonValidationErrors(['car_license']);

        $payload = $this->driverPayload(email: 'plate@example.com');
        $payload['car_license'] = 'طعب9295';

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/drivers', $payload)
            ->assertCreated()
            ->assertJsonPath('car_license', 'ط ع ب 9295');

        $this->assertDatabaseHas('driver_profiles', [
            'car_license' => 'ط ع ب 9295',
        ]);
    }
}
