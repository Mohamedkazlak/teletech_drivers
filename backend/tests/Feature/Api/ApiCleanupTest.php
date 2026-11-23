<?php

declare(strict_types=1);

namespace Tests\Feature\Api;

use App\Domain\Enums\Branch;
use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Place;
use App\Models\Trip;
use App\Models\TripRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class ApiCleanupTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_malformed_uuid_returns_the_json_not_found_body(): void
    {
        $this->actingAsRole(UserRole::Admin);
        $missing = '00000000-0000-4000-8000-000000000099';

        $cases = [
            ['get', '/api/places/not-a-uuid'],
            ['get', '/api/drivers/not-a-uuid'],
            ['get', '/api/employees/not-a-uuid'],
            ['get', '/api/trip-requests/not-a-uuid'],
            ['get', '/api/trips/not-a-uuid'],
            ['get', '/api/trips/not-a-uuid/report'],
            ['get', '/api/drivers/not-a-uuid/attendance'],
            ['patch', '/api/places/not-a-uuid'],
            ['delete', '/api/drivers/not-a-uuid'],
        ];

        foreach ($cases as [$method, $uri]) {
            $this->json($method, $uri)
                ->assertNotFound()
                ->assertExactJson(['message' => 'Resource not found.']);
        }

        $this->getJson('/api/drivers/'.$missing)
            ->assertNotFound()
            ->assertExactJson(['message' => 'Resource not found.']);
        $this->getJson('/api/employees/'.$missing)
            ->assertNotFound()
            ->assertExactJson(['message' => 'Resource not found.']);
        $this->getJson('/api/trips/'.$missing)
            ->assertNotFound()
            ->assertJson(['message' => 'Trip not found.']);
    }

    public function test_admin_lists_trip_requests_with_the_shared_filters(): void
    {
        $this->travelTo(Carbon::parse('2026-11-10 15:00:00', 'Africa/Cairo'));

        $hq = $this->createUserWithRole(UserRole::Employee);
        $hq->branch = Branch::CompanyHeadquarters;
        $hq->save();
        $other = $this->createUserWithRole(UserRole::Employee);
        $other->branch = Branch::NewHeadquarters;
        $other->save();

        $inWeek = $this->createPendingRequest($hq);
        $inWeek->requested_at = $this->cairo('2026-11-10 09:00:00');
        $inWeek->save();

        $otherWeek = $this->createPendingRequest($hq);
        $otherWeek->requested_at = $this->cairo('2026-11-01 09:00:00');
        $otherWeek->save();

        $otherBranch = $this->createPendingRequest($other);
        $otherBranch->requested_at = $this->cairo('2026-11-10 11:00:00');
        $otherBranch->save();

        $linked = $this->createApprovedUnlinkedRequest($hq);
        $linked->requested_at = $this->cairo('2026-11-10 12:00:00');
        $trip = $this->createUnassignedTrip($this->createUserWithRole(UserRole::DriversAdmin));
        $linked->trip_id = $trip->id;
        $linked->save();

        $this->actingAsRole(UserRole::Admin);

        $all = collect($this->getJson('/api/trip-requests')->assertOk()->json('data'))->pluck('id');
        $this->assertTrue($all->contains($inWeek->id));
        $this->assertTrue($all->contains($otherWeek->id));

        $week = collect($this->getJson('/api/trip-requests?period=week&date=2026-11-10')->assertOk()->json('data'))
            ->pluck('id');
        $this->assertTrue($week->contains($inWeek->id));
        $this->assertTrue($week->contains($otherBranch->id));
        $this->assertTrue($week->contains($linked->id));
        $this->assertFalse($week->contains($otherWeek->id));

        $pending = collect($this->getJson('/api/trip-requests?status=pending&period=week&date=2026-11-10')
            ->assertOk()->json('data'))->pluck('id');
        $this->assertTrue($pending->contains($inWeek->id));
        $this->assertFalse($pending->contains($linked->id));

        $branch = collect($this->getJson('/api/trip-requests?branch=new_headquarters')->assertOk()->json('data'))
            ->pluck('id')->all();
        $this->assertSame([$otherBranch->id], $branch);

        $withoutTrip = collect($this->getJson('/api/trip-requests?has_trip=false')->assertOk()->json('data'))->pluck('id');
        $this->assertFalse($withoutTrip->contains($linked->id));
        $this->assertTrue($withoutTrip->contains($inWeek->id));

        foreach (['true', '1'] as $truthy) {
            $withTrip = collect($this->getJson('/api/trip-requests?has_trip='.$truthy)->assertOk()->json('data'))
                ->pluck('id');
            $this->assertTrue($withTrip->contains($linked->id));
            $this->assertFalse($withTrip->contains($inWeek->id));
        }
        $this->getJson('/api/trip-requests?has_trip=0')->assertOk();
        $this->getJson('/api/trip-requests?has_trip=maybe')->assertJsonValidationErrors(['has_trip']);

        $needsDriver = collect($this->getJson('/api/trip-requests?stage=needs_driver&status=approved')
            ->assertOk()->json('data'))->pluck('id');
        $this->assertFalse($needsDriver->contains($linked->id));

        $assigned = collect($this->getJson('/api/trip-requests?stage=assigned')->assertOk()->json('data'))
            ->pluck('id')->all();
        $this->assertSame([$linked->id], $assigned);

        $page = $this->getJson('/api/trip-requests?per_page=1&page=1')->assertOk()->json();
        $this->assertCount(1, $page['data']);
        $this->assertSame(1, $page['meta']['per_page']);
        $this->assertGreaterThan(1, $page['meta']['total']);

        $this->actingAsRole(UserRole::DriversAdmin);
        $forced = collect($this->getJson('/api/trip-requests?status=pending&period=week&date=2026-11-10')
            ->assertOk()->json('data'))->pluck('id');
        $this->assertFalse($forced->contains($inWeek->id));
        $this->assertTrue($forced->contains($linked->id));

        $this->actingAsRole(UserRole::Employee)->getJson('/api/trip-requests')->assertForbidden();
        $this->actingAsRole(UserRole::Driver)->getJson('/api/trip-requests')->assertForbidden();
    }

    public function test_admin_dashboard_counts_and_saturday_week_boundary(): void
    {
        $this->travelTo(Carbon::parse('2026-11-10 15:00:00', 'Africa/Cairo'));

        $this->createUserWithRole(UserRole::Driver);
        $inactive = $this->createUserWithRole(UserRole::Driver);
        $inactive->is_active = false;
        $inactive->save();
        $this->createUserWithRole(UserRole::Driver);
        $deletedDriver = $this->createUserWithRole(UserRole::Driver);
        $deletedDriver->delete();

        $employee = $this->createUserWithRole(UserRole::Employee);
        $inactiveEmployee = $this->createUserWithRole(UserRole::Employee);
        $inactiveEmployee->is_active = false;
        $inactiveEmployee->save();
        $deletedEmployee = $this->createUserWithRole(UserRole::Employee);
        $deletedEmployee->delete();

        Place::factory()->create(['is_active' => true]);
        Place::factory()->create(['is_active' => false]);
        Place::factory()->create()->delete();

        $admin = $this->createUserWithRole(UserRole::Admin);
        $this->trip($admin, TripStatus::Unassigned);
        $this->trip($admin, TripStatus::Assigned);
        $this->trip($admin, TripStatus::Going);
        $this->trip($admin, TripStatus::AtDestination);
        $this->trip($admin, TripStatus::Returning);
        $this->trip($admin, TripStatus::Completed, $this->cairo('2026-11-10 08:00:00'));
        $this->trip($admin, TripStatus::Completed, $this->cairo('2026-11-07 01:00:00'));
        $this->trip($admin, TripStatus::Completed, $this->cairo('2026-11-06 23:00:00'));
        $this->trip($admin, TripStatus::Completed, $this->cairo('2026-11-14 00:00:00'));
        $this->trip($admin, TripStatus::Completed, $this->cairo('2026-01-01 12:00:00'), TripConfirmationStatus::Unconfirmed);
        $this->trip($admin, TripStatus::Completed, $this->cairo('2026-01-02 12:00:00'), TripConfirmationStatus::Unconfirmed);

        $this->requestWithStatus($employee, TripRequestStatus::Pending);
        $this->requestWithStatus($employee, TripRequestStatus::Pending);
        $this->requestWithStatus($employee, TripRequestStatus::Approved);
        $this->requestWithStatus($employee, TripRequestStatus::Rejected);
        $this->requestWithStatus($employee, TripRequestStatus::Cancelled);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/admin/dashboard')
            ->assertOk()
            ->assertExactJson([
                'data' => [
                    'drivers' => ['total' => 3, 'checked_in' => 0, 'checked_out' => 0, 'absent' => 3],
                    'employees_total' => 2,
                    'places_total' => 2,
                    'trips' => [
                        'unassigned' => 1,
                        'assigned' => 1,
                        'in_progress' => 3,
                        'completed_today' => 1,
                        'completed_this_week' => 2,
                    ],
                    'requests' => ['pending' => 2, 'approved' => 1, 'rejected' => 1],
                    'unconfirmed_trips' => 2,
                ],
            ]);

        foreach ([UserRole::CompanyAdmin, UserRole::DriversAdmin, UserRole::Driver, UserRole::Employee] as $role) {
            $this->actingAsRole($role)->getJson('/api/admin/dashboard')->assertForbidden();
        }

        $this->app['auth']->forgetGuards();
        $this->getJson('/api/admin/dashboard')->assertUnauthorized();
    }

    public function test_my_trips_is_scoped_by_role_and_keeps_the_old_lists(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        $otherDriver = $this->createUserWithRole(UserRole::Driver);
        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $otherCreator = $this->createUserWithRole(UserRole::DriversAdmin);
        $admin = $this->createUserWithRole(UserRole::Admin);
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $employee = $this->createUserWithRole(UserRole::Employee);
        $someoneElse = $this->createUserWithRole(UserRole::Employee);

        $assigned = $this->scopedTrip($driversAdmin, $driver, TripStatus::Assigned);
        $this->linkRequest($driversAdmin, $assigned, UserRole::DriversAdmin);
        $completed = $this->scopedTrip($driversAdmin, $driver, TripStatus::Completed);
        $completed->driver_showed_up = true;
        $completed->save();
        $otherAssignment = $this->scopedTrip($driversAdmin, $otherDriver, TripStatus::Assigned);
        $createdByOther = $this->scopedTrip($otherCreator, $driver, TripStatus::Going);

        $adminTrip = $this->scopedTrip($driversAdmin, $driver, TripStatus::Assigned);
        $this->linkRequest($admin, $adminTrip, UserRole::Admin);
        $companyTrip = $this->scopedTrip($otherCreator, $otherDriver, TripStatus::Going);
        $this->linkRequest($companyAdmin, $companyTrip, UserRole::CompanyAdmin);
        $employeeTrip = $this->scopedTrip($driversAdmin, $driver, TripStatus::Assigned);
        $this->linkRequest($employee, $employeeTrip, UserRole::Employee);
        $foreignTrip = $this->scopedTrip($driversAdmin, $driver, TripStatus::Assigned);
        $this->linkRequest($someoneElse, $foreignTrip, UserRole::Employee);

        $this->actingAs($driver, 'sanctum');
        $driverIds = collect($this->getJson('/api/my-trips')->assertOk()->json('data'))->pluck('id');
        $this->assertTrue($driverIds->contains($assigned->id));
        $this->assertTrue($driverIds->contains($completed->id));
        $this->assertFalse($driverIds->contains($otherAssignment->id));
        $mine = $this->getJson('/api/my-trips')->json('data.0');
        $this->assertArrayHasKey('going_route', $mine);
        $onlyCompleted = collect($this->getJson('/api/my-trips?status=completed')->assertOk()->json('data'))
            ->pluck('id')->all();
        $this->assertSame([$completed->id], $onlyCompleted);
        $showedUp = collect($this->getJson('/api/my-trips?driver_showed_up=true')->assertOk()->json('data'))
            ->pluck('id')->all();
        $this->assertSame([$completed->id], $showedUp);
        $this->getJson('/api/my-trips?driver_showed_up=0')->assertOk();
        $this->getJson('/api/trips/mine')->assertOk();

        $this->actingAs($driversAdmin, 'sanctum');
        $created = collect($this->getJson('/api/my-trips')->assertOk()->json('data'))->pluck('id');
        $this->assertTrue($created->contains($assigned->id));
        $this->assertFalse($created->contains($createdByOther->id));
        $this->assertArrayHasKey('going_route', $this->getJson('/api/my-trips')->json('data.0'));
        $this->getJson('/api/trips/created-by-me')->assertOk();
        $page = $this->getJson('/api/my-trips?per_page=1')->assertOk()->json();
        $this->assertCount(1, $page['data']);
        $this->assertSame(1, $page['meta']['per_page']);

        $this->actingAs($admin, 'sanctum');
        $adminIds = collect($this->getJson('/api/my-trips')->assertOk()->json('data'))->pluck('id')->all();
        $this->assertSame([$adminTrip->id], $adminIds);
        $this->assertArrayNotHasKey('going_route', $this->getJson('/api/my-trips')->json('data.0'));
        $this->getJson('/api/trips/mine')->assertForbidden();

        $this->actingAs($companyAdmin, 'sanctum');
        $companyIds = collect($this->getJson('/api/my-trips?stage=in_progress')->assertOk()->json('data'))
            ->pluck('id')->all();
        $this->assertSame([$companyTrip->id], $companyIds);

        $this->actingAs($employee, 'sanctum');
        $employeeIds = collect($this->getJson('/api/my-trips')->assertOk()->json('data'))->pluck('id')->all();
        $this->assertSame([$employeeTrip->id], $employeeIds);
        $this->getJson('/api/trips')->assertForbidden();
        $this->assertArrayNotHasKey('going_route', $this->getJson('/api/my-trips')->json('data.0'));
    }

    public function test_change_password_returns_the_auth_me_user(): void
    {
        $user = User::factory()->employee()->create([
            'password' => Hash::make('password123'),
            'must_change_password' => true,
        ]);

        $changed = $this->actingAs($user, 'sanctum')
            ->postJson('/api/auth/change-password', [
                'current_password' => 'password123',
                'password' => 'newpassword123',
                'password_confirmation' => 'newpassword123',
            ])
            ->assertOk()
            ->json();

        $me = $this->getJson('/api/auth/me')->assertOk()->json();
        $this->assertSame($me, $changed);
        $this->assertFalse($changed['must_change_password']);
        $this->assertSame($user->id, $changed['id']);
        $this->assertSame($user->email, $changed['email']);
        $this->assertSame(UserRole::Employee->value, $changed['role']);
    }

    public function test_boolean_query_values_are_accepted_on_every_flag(): void
    {
        $active = Place::factory()->create(['is_active' => true, 'is_headquarters' => false, 'name_en' => 'Active']);
        $inactive = Place::factory()->create(['is_active' => false, 'is_headquarters' => false, 'name_en' => 'Inactive']);
        $hq = Place::factory()->headquarters()->create(['name_en' => 'HQ']);

        $this->actingAsRole(UserRole::Employee);
        foreach (['false', '0'] as $falsy) {
            $ids = collect($this->getJson('/api/places?is_active='.$falsy)->assertOk()->json('data'))->pluck('id');
            $this->assertTrue($ids->contains($inactive->id));
            $this->assertFalse($ids->contains($active->id));
        }
        foreach (['true', '1'] as $truthy) {
            $ids = collect($this->getJson('/api/places?is_active='.$truthy)->assertOk()->json('data'))->pluck('id');
            $this->assertTrue($ids->contains($active->id));
            $this->assertFalse($ids->contains($inactive->id));
            $hqIds = collect($this->getJson('/api/places?is_headquarters='.$truthy)->assertOk()->json('data'))
                ->pluck('id')->all();
            $this->assertSame([$hq->id], $hqIds);
        }
        $this->getJson('/api/places?is_active=yes')->assertJsonValidationErrors(['is_active']);

        $on = $this->createUserWithRole(UserRole::Driver);
        $on->is_active = true;
        $on->save();
        $off = $this->createUserWithRole(UserRole::Driver);
        $off->is_active = false;
        $off->save();

        $this->actingAsRole(UserRole::Admin);
        foreach (['true', 'false', '1', '0'] as $value) {
            $this->getJson('/api/drivers?is_active='.$value)->assertOk();
        }
        $inactiveDrivers = collect($this->getJson('/api/drivers?is_active=false')->assertOk()->json('data'))->pluck('id');
        $this->assertTrue($inactiveDrivers->contains($off->id));
        $this->assertFalse($inactiveDrivers->contains($on->id));

        $activeEmployee = $this->createUserWithRole(UserRole::Employee);
        $inactiveEmployee = $this->createUserWithRole(UserRole::Employee);
        $inactiveEmployee->is_active = false;
        $inactiveEmployee->save();
        $employeeIds = collect($this->getJson('/api/employees?is_active=0')->assertOk()->json('data'))->pluck('id');
        $this->assertTrue($employeeIds->contains($inactiveEmployee->id));
        $this->assertFalse($employeeIds->contains($activeEmployee->id));

        $this->actingAsRole(UserRole::Employee);
        foreach (['true', 'false', '1', '0'] as $value) {
            $this->getJson('/api/trip-requests/mine?awaiting_confirmation='.$value)->assertOk();
        }
        $this->getJson('/api/trip-requests/mine?awaiting_confirmation=maybe')
            ->assertJsonValidationErrors(['awaiting_confirmation']);
    }

    public function test_include_deleted_is_forbidden_for_non_admins_and_honored_for_admin(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        $this->actingAsRole(UserRole::Admin)->deleteJson('/api/drivers/'.$driver->id)->assertOk();
        $driver->refresh();
        $expected = $driver->deleted_at?->format(DATE_ATOM);
        $this->assertNotNull($expected);
        $this->assertMatchesRegularExpression('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+\-]\d{2}:\d{2}$/', $expected);

        $this->actingAsRole(UserRole::CompanyAdmin);
        $visible = collect($this->getJson('/api/drivers')->assertOk()->json('data'))->pluck('id');
        $this->assertFalse($visible->contains($driver->id));
        $this->getJson('/api/drivers?include_deleted=1')->assertForbidden();
        $this->getJson('/api/drivers?include_deleted=true')->assertForbidden();
        $this->getJson('/api/drivers?include_deleted=0')->assertOk();
        $this->getJson('/api/drivers?include_deleted=false')->assertOk();

        $this->actingAsRole(UserRole::DriversAdmin)
            ->getJson('/api/drivers?include_deleted=1')
            ->assertForbidden();

        $included = collect($this->actingAsRole(UserRole::Admin)
            ->getJson('/api/drivers?include_deleted=1')
            ->assertOk()
            ->json('data'))->keyBy('id');
        $this->assertTrue($included->has($driver->id));
        $this->assertSame($expected, $included[$driver->id]['deleted_at']);
        $this->assertSame($driver->deleted_by, $included[$driver->id]['deleted_by']);

        $hidden = collect($this->getJson('/api/drivers?include_deleted=false')->assertOk()->json('data'))->pluck('id');
        $this->assertFalse($hidden->contains($driver->id));

        $employee = $this->createUserWithRole(UserRole::Employee);
        $deleted = $this->actingAsRole(UserRole::Admin)
            ->deleteJson('/api/employees/'.$employee->id)
            ->assertOk()
            ->json();
        $employee->refresh();
        $this->assertSame($employee->id, $deleted['id']);
        $this->assertSame($employee->deleted_at?->format(DATE_ATOM), $deleted['deleted_at']);
        $this->assertFalse($deleted['is_active']);

        $this->actingAsRole(UserRole::CompanyAdmin)->getJson('/api/employees?include_deleted=true')->assertForbidden();
        $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/employees?include_deleted=1')
            ->assertOk()
            ->assertJsonFragment(['id' => $employee->id]);
    }

    public function test_patch_is_partial_and_full_body_still_updates(): void
    {
        $place = Place::factory()->create([
            'name_en' => 'Old',
            'name_ar' => 'قديم',
            'address' => 'Street',
            'is_active' => true,
            'is_headquarters' => false,
        ]);

        $this->actingAsRole(UserRole::Admin)
            ->patchJson('/api/places/'.$place->id, ['name_en' => 'Renamed'])
            ->assertOk()
            ->assertJsonPath('name_en', 'Renamed')
            ->assertJsonPath('name_ar', 'قديم')
            ->assertJsonPath('address', 'Street')
            ->assertJsonPath('is_active', true);

        $this->patchJson('/api/places/'.$place->id, [])
            ->assertOk()
            ->assertJsonPath('name_en', 'Renamed');

        $this->patchJson('/api/places/'.$place->id, ['name_en' => ''])
            ->assertJsonValidationErrors(['name_en']);

        $this->patchJson('/api/places/'.$place->id, [
            'name_en' => 'Full',
            'name_ar' => 'كامل',
            'address' => null,
            'latitude' => 30.2,
            'longitude' => 31.2,
            'is_headquarters' => false,
            'is_active' => false,
        ])
            ->assertOk()
            ->assertJsonPath('name_en', 'Full')
            ->assertJsonPath('name_ar', 'كامل')
            ->assertJsonPath('address', null)
            ->assertJsonPath('is_active', false);

        $driver = $this->createUserWithRole(UserRole::Driver);
        $this->patchJson('/api/drivers/'.$driver->id, ['phone' => '01055556666'])
            ->assertOk()
            ->assertJsonPath('phone', '01055556666')
            ->assertJsonPath('name_en', $driver->name_en)
            ->assertJsonPath('national_id', 'nid')
            ->assertJsonPath('is_active', true);

        $this->patchJson('/api/drivers/'.$driver->id, ['is_active' => false])
            ->assertOk()
            ->assertJsonPath('is_active', false)
            ->assertJsonPath('phone', '01055556666');

        $employee = $this->createUserWithRole(UserRole::Employee);
        $employee->branch = Branch::CompanyHeadquarters;
        $employee->name_ar = null;
        $employee->save();

        $this->patchJson('/api/employees/'.$employee->id, ['is_active' => false])
            ->assertOk()
            ->assertJsonPath('is_active', false)
            ->assertJsonPath('name_en', $employee->name_en)
            ->assertJsonPath('name_ar', null)
            ->assertJsonPath('branch', Branch::CompanyHeadquarters->value);
    }

    public function test_delete_place_returns_the_place_resource(): void
    {
        $place = Place::factory()->create(['name_en' => 'Gone', 'name_ar' => 'راح']);

        $this->actingAsRole(UserRole::Admin)
            ->deleteJson('/api/places/'.$place->id)
            ->assertOk()
            ->assertJsonPath('id', $place->id)
            ->assertJsonPath('name_en', 'Gone')
            ->assertJsonPath('name_ar', 'راح')
            ->assertJsonPath('is_active', $place->is_active)
            ->assertJsonMissingPath('message');

        $this->assertSoftDeleted('places', ['id' => $place->id]);
    }

    public function test_driver_recommendations_count_the_saturday_week(): void
    {
        $this->travelTo(Carbon::parse('2026-11-10 12:00:00', 'Africa/Cairo'));

        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $target = $this->createUnassignedTrip($admin);
        $target->scheduled_at = $this->cairo('2026-12-01 10:00:00');
        $target->save();

        $inside = $this->createUserWithRole(UserRole::Driver);
        $friday = $this->createUserWithRole(UserRole::Driver);
        $nextWeek = $this->createUserWithRole(UserRole::Driver);

        $this->scopedTrip($admin, $inside, TripStatus::Assigned, $this->cairo('2026-11-07 01:00:00'));
        $this->scopedTrip($admin, $friday, TripStatus::Assigned, $this->cairo('2026-11-06 23:00:00'));
        $this->scopedTrip($admin, $nextWeek, TripStatus::Assigned, $this->cairo('2026-11-14 00:00:00'));

        $this->actingAs($admin, 'sanctum');
        $rows = collect($this->getJson('/api/trips/'.$target->id.'/driver-recommendations')
            ->assertOk()
            ->json('data'))->keyBy('driver.id');

        $this->assertSame(1, $rows[$inside->id]['trips_this_week']);
        $this->assertSame(0, $rows[$friday->id]['trips_this_week']);
        $this->assertSame(0, $rows[$nextWeek->id]['trips_this_week']);
    }

    private function cairo(string $local): Carbon
    {
        return Carbon::parse($local, 'Africa/Cairo')->utc();
    }

    private function trip(
        User $createdBy,
        TripStatus $status,
        ?Carbon $finishedAt = null,
        ?TripConfirmationStatus $confirmation = null,
    ): Trip {
        return Trip::factory()->create([
            'created_by' => $createdBy->id,
            'status' => $status,
            'finished_at' => $finishedAt,
            'confirmation_status' => $confirmation,
            'scheduled_at' => $this->cairo('2026-11-10 10:00:00'),
        ]);
    }

    private function requestWithStatus(User $employee, TripRequestStatus $status): TripRequest
    {
        return TripRequest::factory()->create([
            'employee_id' => $employee->id,
            'requester_role' => UserRole::Employee,
            'status' => $status,
        ]);
    }

    private function scopedTrip(
        User $createdBy,
        User $driver,
        TripStatus $status,
        ?Carbon $scheduledAt = null,
    ): Trip {
        return Trip::factory()->create([
            'created_by' => $createdBy->id,
            'driver_id' => $driver->id,
            'status' => $status,
            'scheduled_at' => $scheduledAt ?? now()->addDay(),
            'going_route' => 'SECRET_GOING',
            'return_route' => 'SECRET_RETURN',
            'start_lat' => 30.1,
            'start_lng' => 31.1,
        ]);
    }

    private function linkRequest(User $requester, Trip $trip, UserRole $role): void
    {
        TripRequest::factory()->approved()->create([
            'employee_id' => $requester->id,
            'requester_role' => $role,
            'trip_id' => $trip->id,
        ]);
    }
}
