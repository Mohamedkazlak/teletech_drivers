<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripEndpointsTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_unauthenticated_returns_401(): void
    {
        $this->getJson('/api/trips')->assertUnauthorized();
        $this->postJson('/api/trips/from-requests', [])->assertUnauthorized();
    }

    public function test_from_requests_role_matrix(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $request = $this->createApprovedUnlinkedRequest($employee);

        foreach ([UserRole::Employee, UserRole::CompanyAdmin, UserRole::Admin, UserRole::Driver] as $role) {
            $this->actingAsRole($role)
                ->postJson('/api/trips/from-requests', [
                    'mode' => 'one_per_request',
                    'request_ids' => [$request->id],
                ])
                ->assertForbidden();
        }

        $this->actingAsRole(UserRole::DriversAdmin)
            ->postJson('/api/trips/from-requests', [
                'mode' => 'one_per_request',
                'request_ids' => [$request->id],
            ])
            ->assertCreated()
            ->assertJsonPath('data.0.status', 'unassigned');
    }

    public function test_one_per_request_vs_grouped(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $a = $this->createApprovedUnlinkedRequest($employee);
        $b = $this->createApprovedUnlinkedRequest($employee);

        $this->actingAsRole(UserRole::DriversAdmin)
            ->postJson('/api/trips/from-requests', [
                'mode' => 'one_per_request',
                'request_ids' => [$a->id, $b->id],
            ])
            ->assertCreated()
            ->assertJsonCount(2, 'data');

        $this->assertDatabaseCount('trips', 2);
        $this->assertNotNull($a->fresh()->trip_id);
        $this->assertNotSame($a->fresh()->trip_id, $b->fresh()->trip_id);

        $c = $this->createApprovedUnlinkedRequest($employee);
        $d = $this->createApprovedUnlinkedRequest($employee);

        $this->actingAsRole(UserRole::DriversAdmin)
            ->postJson('/api/trips/from-requests', [
                'mode' => 'grouped',
                'request_ids' => [$c->id, $d->id],
                'scheduled_at' => now()->addDays(3)->toISOString(),
            ])
            ->assertCreated()
            ->assertJsonCount(1, 'data');

        $this->assertSame($c->fresh()->trip_id, $d->fresh()->trip_id);
    }

    public function test_already_linked_or_mixed_invalid_writes_nothing(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $valid = $this->createApprovedUnlinkedRequest($employee);
        $linked = $this->createApprovedUnlinkedRequest($employee);
        $trip = $this->createUnassignedTrip($admin);
        $linked->trip_id = $trip->id;
        $linked->save();

        $before = Trip::query()->count();

        $this->actingAsRole(UserRole::DriversAdmin)
            ->postJson('/api/trips/from-requests', [
                'mode' => 'one_per_request',
                'request_ids' => [$valid->id, $linked->id],
            ])
            ->assertStatus(409);

        $this->assertSame($before, Trip::query()->count());
        $this->assertNull($valid->fresh()->trip_id);
    }

    public function test_assign_reassign_and_invalid_transitions(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);

        Sanctum::actingAs($admin);
        $this->postJson('/api/trips/'.$trip->id.'/assign', ['driver_id' => $driver->id])
            ->assertOk()
            ->assertJsonPath('status', 'assigned')
            ->assertJsonPath('driver_id', $driver->id);

        $this->postJson('/api/trips/'.$trip->id.'/assign', ['driver_id' => $other->id])
            ->assertOk()
            ->assertJsonPath('status', 'assigned')
            ->assertJsonPath('driver_id', $other->id);

        $trip->status = TripStatus::Going;
        $trip->save();

        $this->postJson('/api/trips/'.$trip->id.'/assign', ['driver_id' => $driver->id])
            ->assertStatus(409);

        $inactive = $this->createUserWithRole(UserRole::Driver);
        $inactive->is_active = false;
        $inactive->save();

        $fresh = $this->createUnassignedTrip($admin);
        $this->postJson('/api/trips/'.$fresh->id.'/assign', ['driver_id' => $inactive->id])
            ->assertStatus(422);

        $employee = $this->createUserWithRole(UserRole::Employee);
        $this->postJson('/api/trips/'.$fresh->id.'/assign', ['driver_id' => $employee->id])
            ->assertStatus(422);
    }

    public function test_cancel_trip_keeps_linked_request_trip_id(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $employee = $this->createUserWithRole(UserRole::Employee);
        $trip = $this->createUnassignedTrip($admin);
        $request = $this->createApprovedUnlinkedRequest($employee);
        $request->trip_id = $trip->id;
        $request->save();

        Sanctum::actingAs($admin);
        $this->postJson('/api/trips/'.$trip->id.'/cancel')
            ->assertOk()
            ->assertJsonPath('status', 'cancelled');

        $this->assertSame($trip->id, $request->fresh()->trip_id);
        $this->assertSame(TripRequestStatus::Approved, $request->fresh()->status);

        $going = $this->createUnassignedTrip($admin);
        $going->status = TripStatus::Going;
        $going->save();
        $this->postJson('/api/trips/'.$going->id.'/cancel')->assertStatus(409);
    }

    public function test_visibility_hides_sensitive_fields_for_company_admin_and_admin(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $trip = $this->createUnassignedTrip($creator);

        foreach ([UserRole::CompanyAdmin, UserRole::Admin] as $role) {
            $this->actingAsRole($role)
                ->getJson('/api/trips/'.$trip->id)
                ->assertOk()
                ->assertJsonMissingPath('going_route')
                ->assertJsonMissingPath('return_route')
                ->assertJsonMissingPath('start_lat')
                ->assertJsonMissingPath('start_lng');
        }

        Sanctum::actingAs($creator);
        $this->getJson('/api/trips/'.$trip->id)
            ->assertOk()
            ->assertJsonPath('going_route', 'SECRET_GOING')
            ->assertJsonPath('start_lat', 30.1);
    }

    public function test_driver_sees_only_own_trips(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);

        $mine = Trip::factory()->create([
            'created_by' => $admin->id,
            'driver_id' => $driver->id,
            'status' => TripStatus::Assigned,
            'going_route' => 'R',
        ]);
        $theirs = Trip::factory()->create([
            'created_by' => $admin->id,
            'driver_id' => $other->id,
            'status' => TripStatus::Assigned,
        ]);

        Sanctum::actingAs($driver);
        $this->getJson('/api/trips/mine')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $mine->id);

        $this->getJson('/api/trips/'.$mine->id)->assertOk();
        $this->getJson('/api/trips/'.$theirs->id)->assertForbidden();
        $this->getJson('/api/trips')->assertForbidden();
    }

    public function test_list_trips_role_matrix(): void
    {
        $this->actingAsRole(UserRole::CompanyAdmin)->getJson('/api/trips')->assertOk();
        $this->actingAsRole(UserRole::DriversAdmin)->getJson('/api/trips')->assertOk();
        $this->actingAsRole(UserRole::Admin)->getJson('/api/trips')->assertOk();
        $this->actingAsRole(UserRole::Employee)->getJson('/api/trips')->assertForbidden();
        $this->actingAsRole(UserRole::Driver)->getJson('/api/trips')->assertForbidden();
    }
}
