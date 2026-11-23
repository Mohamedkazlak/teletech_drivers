<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\TripRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class DriversAdminTripPartitionTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_own_requested_trip_is_only_on_my_trips_and_another_users_trip_is_only_on_trips(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $employee = $this->createUserWithRole(UserRole::Employee);
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $platformAdmin = $this->createUserWithRole(UserRole::Admin);

        $own = $this->createUnassignedTrip($employee);
        $this->requestedBy($admin, $own);

        $someoneElses = $this->createUnassignedTrip($admin);
        $someoneElses->status = TripStatus::Assigned;
        $someoneElses->save();
        $this->requestedBy($employee, $someoneElses);

        Sanctum::actingAs($admin);

        $mine = $this->ids('/api/my-trips?per_page=100');
        $fleet = $this->ids('/api/trips?per_page=100');
        $unassigned = $this->ids('/api/trips?stage=unassigned&per_page=100');

        $this->assertContains($own->id, $mine);
        $this->assertNotContains($someoneElses->id, $mine);
        $this->assertContains($someoneElses->id, $fleet);
        $this->assertNotContains($own->id, $fleet);
        $this->assertNotContains($own->id, $unassigned);
        $this->assertSame([], array_values(array_intersect($mine, $fleet)));

        Sanctum::actingAs($companyAdmin);
        $companyTrips = $this->ids('/api/trips?per_page=100');
        $this->assertContains($own->id, $companyTrips);
        $this->assertContains($someoneElses->id, $companyTrips);
        $this->assertSame([], $this->ids('/api/my-trips?per_page=100'));

        Sanctum::actingAs($platformAdmin);
        $adminTrips = $this->ids('/api/trips?per_page=100');
        $this->assertContains($own->id, $adminTrips);
        $this->assertContains($someoneElses->id, $adminTrips);

        $companyOwn = $this->createUnassignedTrip($companyAdmin);
        $this->requestedBy($companyAdmin, $companyOwn);
        Sanctum::actingAs($companyAdmin);
        $this->assertContains($companyOwn->id, $this->ids('/api/trips?per_page=100'));
        $this->assertContains($companyOwn->id, $this->ids('/api/my-trips?per_page=100'));
    }

    public function test_own_auto_accepted_unassigned_trip_stays_on_my_trips_only(): void
    {
        $owner = $this->createUserWithRole(UserRole::DriversAdmin);
        Sanctum::actingAs($owner);
        $tripId = $this->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated()
            ->json('trip_id');
        $this->assertNotNull($tripId);

        $this->assertContains($tripId, $this->ids('/api/my-trips?per_page=100'));
        $this->assertNotContains($tripId, $this->ids('/api/trips?stage=unassigned&per_page=100'));
        $this->assertNotContains($tripId, $this->ids('/api/trips?per_page=100'));

        $this->actingAsRole(UserRole::DriversAdmin);
        $this->assertNotContains($tripId, $this->ids('/api/my-trips?per_page=100'));
        $this->assertContains($tripId, $this->ids('/api/trips?stage=unassigned&per_page=100'));

        Sanctum::actingAs($owner);
        $this->assertContains($tripId, $this->ids('/api/my-trips?bucket=active&per_page=100'));
    }

    private function requestedBy(User $requester, Trip $trip): void
    {
        TripRequest::factory()->approved()->create([
            'employee_id' => $requester->id,
            'requester_role' => $requester->role,
            'trip_id' => $trip->id,
        ]);
    }

    /**
     * @return list<string>
     */
    private function ids(string $url): array
    {
        return collect($this->getJson($url)->assertOk()->json('data'))->pluck('id')->all();
    }
}
