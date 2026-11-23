<?php

declare(strict_types=1);

namespace Tests\Feature\Places;

use App\Domain\Enums\UserRole;
use App\Models\Place;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class PlaceEndpointsTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_unauthenticated_requests_return_401(): void
    {
        $place = Place::factory()->create();

        $this->getJson('/api/places')->assertUnauthorized();
        $this->getJson('/api/places/'.$place->id)->assertUnauthorized();
        $this->postJson('/api/places', [])->assertUnauthorized();
        $this->patchJson('/api/places/'.$place->id, [])->assertUnauthorized();
        $this->deleteJson('/api/places/'.$place->id)->assertUnauthorized();
    }

    public function test_any_authenticated_role_can_read_places(): void
    {
        Place::factory()->create(['name_en' => 'Readable']);

        foreach ($this->allRoles() as $role) {
            $this->actingAsRole($role)
                ->getJson('/api/places')
                ->assertOk()
                ->assertJsonPath('data.0.name_en', 'Readable');
        }
    }

    /**
     * @return list<array{0: UserRole, 1: int}>
     */
    public static function writeRoleMatrix(): array
    {
        return [
            [UserRole::Admin, 201],
            [UserRole::CompanyAdmin, 201],
            [UserRole::DriversAdmin, 201],
            [UserRole::Driver, 403],
            [UserRole::Employee, 403],
        ];
    }

    #[DataProvider('writeRoleMatrix')]
    public function test_create_place_role_matrix(UserRole $role, int $status): void
    {
        $this->actingAsRole($role)
            ->postJson('/api/places', [
                'name_en' => 'New Place',
                'name_ar' => 'مكان',
                'address' => 'القاهرة',
                'latitude' => 30.0,
                'longitude' => 31.0,
                'is_headquarters' => false,
                'is_active' => true,
            ])
            ->assertStatus($status);
    }

    #[DataProvider('writeRoleMatrix')]
    public function test_update_place_role_matrix(UserRole $role, int $expectedCreateStatus): void
    {
        $place = Place::factory()->create();
        $expected = $expectedCreateStatus === 201 ? 200 : 403;

        $this->actingAsRole($role)
            ->patchJson('/api/places/'.$place->id, [
                'name_en' => 'Updated',
                'name_ar' => 'محدث',
                'latitude' => 30.1,
                'longitude' => 31.1,
                'is_headquarters' => false,
                'is_active' => true,
            ])
            ->assertStatus($expected);
    }

    public function test_rejects_second_active_headquarters_with_422(): void
    {
        Place::factory()->headquarters()->create();

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/places', [
                'name_en' => 'Second HQ',
                'name_ar' => 'مقر ٢',
                'address' => 'القاهرة',
                'latitude' => 30.0,
                'longitude' => 31.0,
                'is_headquarters' => true,
                'is_active' => true,
            ])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Only one active headquarters place is allowed.');
    }

    public function test_rejects_partial_coordinates(): void
    {
        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/places', [
                'name_en' => 'Bad Coords',
                'name_ar' => 'سيء',
                'address' => 'القاهرة',
                'latitude' => 30.0,
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['longitude']);
    }

    public function test_allows_deactivating_headquarters(): void
    {
        $hq = Place::factory()->headquarters()->create();

        $this->actingAsRole(UserRole::Admin)
            ->patchJson('/api/places/'.$hq->id, [
                'name_en' => $hq->name_en,
                'name_ar' => $hq->name_ar,
                'latitude' => (float) $hq->latitude,
                'longitude' => (float) $hq->longitude,
                'is_headquarters' => true,
                'is_active' => false,
            ])
            ->assertOk()
            ->assertJsonPath('is_active', false);
    }

    public function test_search_and_filters(): void
    {
        Place::factory()->create(['name_en' => 'Alpha Site', 'name_ar' => 'ألف', 'is_active' => true]);
        Place::factory()->inactive()->create(['name_en' => 'Beta Site', 'name_ar' => 'باء']);

        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/places?search=Alpha&is_active=1')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.name_en', 'Alpha Site');
    }

    public function test_place_includes_created_at_for_every_role(): void
    {
        $place = Place::factory()->create();
        $place->refresh();
        $expected = $place->created_at?->format(DATE_ATOM);
        $this->assertIsString($expected);
        $this->assertMatchesRegularExpression('/\+00:00$/', $expected);

        foreach ($this->allRoles() as $role) {
            $this->actingAsRole($role)
                ->getJson('/api/places/'.$place->id)
                ->assertOk()
                ->assertJsonPath('created_at', $expected)
                ->assertJsonPath('name_en', $place->name_en);
        }

        $this->actingAsRole(UserRole::Driver)
            ->patchJson('/api/places/'.$place->id, [
                'name_en' => 'Nope',
                'name_ar' => 'لا',
                'is_headquarters' => false,
                'is_active' => true,
            ])
            ->assertForbidden();
    }

    public function test_place_created_at_can_be_null(): void
    {
        $place = Place::factory()->create();
        Place::query()->whereKey($place->id)->update(['created_at' => null]);

        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/places/'.$place->id)
            ->assertOk()
            ->assertJsonPath('created_at', null)
            ->assertJsonPath('is_active', true);
    }

    /**
     * @return list<array{0: UserRole, 1: int}>
     */
    public static function deleteRoleMatrix(): array
    {
        return [
            [UserRole::Admin, 200],
            [UserRole::CompanyAdmin, 200],
            [UserRole::DriversAdmin, 200],
            [UserRole::Driver, 403],
            [UserRole::Employee, 403],
        ];
    }

    #[DataProvider('deleteRoleMatrix')]
    public function test_delete_place_role_matrix(UserRole $role, int $status): void
    {
        $place = Place::factory()->create();

        $this->actingAsRole($role)
            ->deleteJson('/api/places/'.$place->id)
            ->assertStatus($status);

        if ($status === 200) {
            $this->assertSoftDeleted('places', ['id' => $place->id]);
        } else {
            $this->assertDatabaseHas('places', ['id' => $place->id, 'deleted_at' => null]);
        }
    }

    public function test_delete_removes_favorites_and_hides_place_from_index(): void
    {
        $place = Place::factory()->create(['name_en' => 'Drop Me']);
        $keep = Place::factory()->create(['name_en' => 'Keep Me']);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $driver->favoritePlaces()->attach($place->id);

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->deleteJson('/api/places/'.$place->id)
            ->assertOk()
            ->assertJsonPath('id', $place->id)
            ->assertJsonPath('name_en', 'Drop Me')
            ->assertJsonMissingPath('message');

        $this->assertSoftDeleted('places', ['id' => $place->id]);
        $this->assertDatabaseMissing('driver_favorite_places', [
            'user_id' => $driver->id,
            'place_id' => $place->id,
        ]);

        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/places')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.name_en', 'Keep Me');

        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/places/'.$place->id)
            ->assertNotFound();

        $this->assertFalse($keep->fresh()->trashed());
    }

    public function test_cannot_delete_headquarters_place(): void
    {
        $hq = Place::factory()->headquarters()->create();

        $this->actingAsRole(UserRole::Admin)
            ->deleteJson('/api/places/'.$hq->id)
            ->assertStatus(422)
            ->assertJsonPath('message', 'The headquarters place cannot be deleted.');

        $hq->refresh();
        $this->assertTrue($hq->is_headquarters);
        $this->assertNull($hq->deleted_at);

        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/places/'.$hq->id)
            ->assertOk()
            ->assertJsonPath('is_headquarters', true);
    }

    public function test_create_requires_address_and_allows_a_place_without_coordinates(): void
    {
        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/places', [
                'name_en' => 'No Address',
                'name_ar' => 'بلا عنوان',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['address']);

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/places', [
                'name_en' => 'Named only',
                'name_ar' => 'بالاسم',
                'address' => 'القاهرة',
            ])
            ->assertCreated()
            ->assertJsonPath('address', 'القاهرة')
            ->assertJsonPath('latitude', null)
            ->assertJsonPath('longitude', null);
    }
}
