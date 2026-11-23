<?php

declare(strict_types=1);

namespace Tests\Feature\TripRequests;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripRequestEndpointsTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_unauthenticated_returns_401(): void
    {
        $this->postJson('/api/trip-requests', [])->assertUnauthorized();
        $this->getJson('/api/trip-requests/mine')->assertUnauthorized();
        $this->getJson('/api/trip-requests')->assertUnauthorized();
    }

    /**
     * @return list<array{0: UserRole, 1: int}>
     */
    public static function createRoleMatrix(): array
    {
        return [
            [UserRole::Employee, 201],
            [UserRole::CompanyAdmin, 201],
            [UserRole::Admin, 201],
            [UserRole::DriversAdmin, 201],
            [UserRole::Driver, 403],
        ];
    }

    #[DataProvider('createRoleMatrix')]
    public function test_create_role_matrix(UserRole $role, int $status): void
    {
        $this->actingAsRole($role)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertStatus($status);
    }

    public function test_employee_creates_pending_not_auto_approved(): void
    {
        $this->actingAsRole(UserRole::Employee)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated()
            ->assertJsonPath('status', 'pending')
            ->assertJsonPath('auto_approved', false)
            ->assertJsonPath('trip_id', null)
            ->assertJsonPath('requester_role', 'employee');
    }

    public function test_company_admin_auto_approves_without_trip(): void
    {
        $response = $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated();

        $response
            ->assertJsonPath('status', 'approved')
            ->assertJsonPath('auto_approved', true)
            ->assertJsonPath('trip_id', null)
            ->assertJsonPath('handled_by', $this->actingUser?->id);

        $this->assertDatabaseCount('trips', 0);
    }

    public function test_admin_auto_approves_without_trip(): void
    {
        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated()
            ->assertJsonPath('status', 'approved')
            ->assertJsonPath('auto_approved', true)
            ->assertJsonPath('trip_id', null);

        $this->assertDatabaseCount('trips', 0);
    }

    public function test_drivers_admin_creates_linked_unassigned_trip(): void
    {
        $response = $this->actingAsRole(UserRole::DriversAdmin)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated();

        $tripId = $response->json('trip_id');
        $this->assertNotNull($tripId);
        $this->assertDatabaseHas('trips', [
            'id' => $tripId,
            'status' => TripStatus::Unassigned->value,
            'created_by' => $this->actingUser?->id,
        ]);
        $this->assertDatabaseCount('trips', 1);
        $this->assertDatabaseHas('trips', [
            'id' => $tripId,
            'driver_id' => null,
            'status' => TripStatus::Unassigned->value,
        ]);
        $response
            ->assertJsonPath('status', TripRequestStatus::Approved->value)
            ->assertJsonPath('auto_approved', true)
            ->assertJsonPath('handled_by', $this->actingUser?->id);

        $owner = $this->actingUser;

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->getJson('/api/trip-requests?status=pending')
            ->assertOk()
            ->assertJsonMissing(['id' => $response->json('id')]);

        $this->actingAsRole(UserRole::DriversAdmin);
        $mine = collect($this->getJson('/api/my-trips')->assertOk()->json('data'))
            ->pluck('id')
            ->all();
        $this->assertNotContains($tripId, $mine);

        $this->actingAs($owner, 'sanctum');
        $unassigned = collect($this->getJson('/api/trips?stage=unassigned')->assertOk()->json('data'))
            ->pluck('id')
            ->all();
        $this->assertNotContains($tripId, $unassigned);

        $created = collect($this->getJson('/api/my-trips')->assertOk()->json('data'))
            ->pluck('id')
            ->all();
        $this->assertContains($tripId, $created);

        $driver = $this->createUserWithRole(UserRole::Driver);
        $this->actingAs($owner, 'sanctum')
            ->postJson('/api/trips/'.$tripId.'/assign', ['driver_id' => $driver->id])
            ->assertOk()
            ->assertJsonPath('status', 'assigned')
            ->assertJsonPath('driver_id', $driver->id);
    }

    public function test_company_admin_own_request_stays_approved_and_out_of_pending(): void
    {
        $response = $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated()
            ->assertJsonPath('status', 'approved')
            ->assertJsonPath('auto_approved', true)
            ->assertJsonPath('trip_id', null);

        $this->getJson('/api/trip-requests?status=pending')
            ->assertOk()
            ->assertJsonMissing(['id' => $response->json('id')]);

        $this->actingAsRole(UserRole::DriversAdmin)
            ->getJson('/api/trip-requests?status=approved')
            ->assertOk()
            ->assertJsonFragment(['id' => $response->json('id')]);
    }

    public function test_employee_request_stays_pending_for_company_admin(): void
    {
        $created = $this->actingAsRole(UserRole::Employee)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated()
            ->assertJsonPath('status', 'pending')
            ->assertJsonPath('auto_approved', false)
            ->assertJsonPath('trip_id', null);

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->getJson('/api/trip-requests?status=pending')
            ->assertOk()
            ->assertJsonFragment(['id' => $created->json('id')]);
    }

    public function test_drivers_admin_create_rolls_back_both_on_failure(): void
    {
        $this->actingAsRole(UserRole::DriversAdmin);
        $payload = $this->tripRequestPayload();

        DB::listen(function ($query): void {
            $sql = strtolower($query->sql);
            if (str_contains($sql, 'insert into "trips"') || str_contains($sql, 'insert into `trips`')) {
                throw new \RuntimeException('Simulated trip insert failure');
            }
        });

        try {
            $this->withoutExceptionHandling();
            $this->postJson('/api/trip-requests', $payload);
            $this->fail('Expected trip insert failure');
        } catch (\RuntimeException $e) {
            $this->assertSame('Simulated trip insert failure', $e->getMessage());
        }

        $this->assertDatabaseCount('trip_requests', 0);
        $this->assertDatabaseCount('trips', 0);
    }

    public function test_list_admin_role_matrix(): void
    {
        $this->actingAsRole(UserRole::CompanyAdmin)->getJson('/api/trip-requests')->assertOk();
        $this->actingAsRole(UserRole::DriversAdmin)->getJson('/api/trip-requests')->assertOk();
        $this->actingAsRole(UserRole::Admin)->getJson('/api/trip-requests')->assertOk();
        $this->actingAsRole(UserRole::Employee)->getJson('/api/trip-requests')->assertForbidden();
        $this->actingAsRole(UserRole::Driver)->getJson('/api/trip-requests')->assertForbidden();
    }

    public function test_approve_reject_only_pending_and_company_admin(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $pending = $this->createPendingRequest($employee);

        $this->actingAsRole(UserRole::DriversAdmin)
            ->postJson('/api/trip-requests/'.$pending->id.'/approve')
            ->assertForbidden();

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests/'.$pending->id.'/approve')
            ->assertOk()
            ->assertJsonPath('status', 'approved');

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests/'.$pending->id.'/approve')
            ->assertStatus(409);

        $pending2 = $this->createPendingRequest($employee);
        $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests/'.$pending2->id.'/reject', [
                'rejection_reason' => 'no seats',
            ])
            ->assertOk()
            ->assertJsonPath('status', 'rejected')
            ->assertJsonPath('rejection_reason', 'no seats');
    }

    public function test_approve_group_all_or_nothing_shared_group_id(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $a = $this->createPendingRequest($employee);
        $b = $this->createPendingRequest($employee);
        $approved = $this->createApprovedUnlinkedRequest($employee);

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests/approve-group', [
                'request_ids' => [$a->id, $approved->id],
            ])
            ->assertStatus(409);

        $this->assertDatabaseHas('trip_requests', [
            'id' => $a->id,
            'status' => TripRequestStatus::Pending->value,
        ]);

        $response = $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests/approve-group', [
                'request_ids' => [$a->id, $b->id],
            ])
            ->assertOk();

        $groupA = $response->json('data.0.suggested_group_id');
        $groupB = $response->json('data.1.suggested_group_id');
        $this->assertNotNull($groupA);
        $this->assertSame($groupA, $groupB);
    }

    public function test_cancel_rules(): void
    {
        $owner = $this->createUserWithRole(UserRole::Employee);
        $other = $this->createUserWithRole(UserRole::Employee);
        $pending = $this->createPendingRequest($owner);
        $approved = $this->createApprovedUnlinkedRequest($owner);

        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $trip = $this->createUnassignedTrip($admin);
        $linked = $this->createApprovedUnlinkedRequest($owner);
        $linked->trip_id = $trip->id;
        $linked->save();

        Sanctum::actingAs($other);
        $this->postJson('/api/trip-requests/'.$pending->id.'/cancel')->assertForbidden();

        Sanctum::actingAs($owner);
        $this->postJson('/api/trip-requests/'.$pending->id.'/cancel')
            ->assertOk()
            ->assertJsonPath('status', 'cancelled');

        $this->postJson('/api/trip-requests/'.$approved->id.'/cancel')
            ->assertOk()
            ->assertJsonPath('status', 'cancelled');

        $this->postJson('/api/trip-requests/'.$linked->id.'/cancel')->assertStatus(409);
    }

    public function test_driver_can_view_request_only_when_assigned_trip(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $otherDriver = $this->createUserWithRole(UserRole::Driver);
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);

        $trip = Trip::factory()->create([
            'created_by' => $admin->id,
            'driver_id' => $driver->id,
            'status' => TripStatus::Assigned,
        ]);

        $request = $this->createApprovedUnlinkedRequest($employee);
        $request->trip_id = $trip->id;
        $request->save();

        Sanctum::actingAs($driver);
        $this->getJson('/api/trip-requests/'.$request->id)->assertOk();

        Sanctum::actingAs($otherDriver);
        $this->getJson('/api/trip-requests/'.$request->id)->assertForbidden();
    }

    public function test_grouping_suggestions_role_matrix(): void
    {
        $this->actingAsRole(UserRole::CompanyAdmin)
            ->getJson('/api/trip-requests/grouping-suggestions')
            ->assertOk();
        $this->actingAsRole(UserRole::DriversAdmin)
            ->getJson('/api/trip-requests/grouping-suggestions')
            ->assertOk();
        $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/trip-requests/grouping-suggestions')
            ->assertForbidden();
        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/trip-requests/grouping-suggestions')
            ->assertForbidden();
    }

    public function test_place_id_snapshot_ignores_client_values(): void
    {
        $place = $this->createActivePlace('ServerName');
        $dest = $this->createActivePlace('Dest');

        $this->actingAsRole(UserRole::Employee)
            ->postJson('/api/trip-requests', [
                'pickup' => [
                    'place_id' => $place->id,
                    'name' => 'ClientOverride',
                    'lat' => 1.0,
                    'lng' => 2.0,
                ],
                'destination' => ['place_id' => $dest->id],
                'requested_at' => now()->addDays(2)->toISOString(),
            ])
            ->assertCreated()
            ->assertJsonPath('pickup.name', 'ServerName')
            ->assertJsonPath('pickup.lat', (float) $place->latitude);
    }
}
