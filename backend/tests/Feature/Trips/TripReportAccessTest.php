<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\TripRequest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripReportAccessTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_report_access_follows_the_trip_list_and_the_assigned_driver(): void
    {
        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $otherDriver = $this->createUserWithRole(UserRole::Driver);
        $employee = $this->createUserWithRole(UserRole::Employee);

        $trip = Trip::factory()->create([
            'created_by' => $driversAdmin->id,
            'driver_id' => $driver->id,
            'status' => TripStatus::Completed,
            'going_route' => 'encoded',
            'return_route' => 'encoded-back',
        ]);
        TripRequest::factory()->approved()->create([
            'employee_id' => $employee->id,
            'requester_role' => UserRole::Employee,
            'trip_id' => $trip->id,
        ]);
        $unlinked = $this->createUnassignedTrip($driversAdmin);

        foreach ([UserRole::Admin, UserRole::DriversAdmin, UserRole::CompanyAdmin] as $role) {
            $this->actingAsRole($role)
                ->getJson('/api/trips/'.$trip->id.'/report')
                ->assertOk()
                ->assertJsonPath('status', 'completed')
                ->assertJsonPath('going_route', 'encoded')
                ->assertJsonPath('driven_route', []);

            $this->getJson('/api/trips/'.$unlinked->id.'/report')
                ->assertOk()
                ->assertJsonPath('driven_route', []);
        }

        $this->actingAs($driver, 'sanctum')
            ->getJson('/api/trips/'.$trip->id.'/report')
            ->assertOk()
            ->assertJsonPath('driven_route', []);

        $this->actingAs($otherDriver, 'sanctum')
            ->getJson('/api/trips/'.$trip->id.'/report')
            ->assertNotFound()
            ->assertJsonPath('message', 'Trip not found.');

        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/trips/'.$trip->id.'/report')
            ->assertForbidden();

        $missing = '00000000-0000-4000-8000-000000000099';
        $this->actingAsRole(UserRole::CompanyAdmin)
            ->getJson('/api/trips/'.$missing.'/report')
            ->assertNotFound()
            ->assertJsonPath('message', 'Trip not found.');
    }
}
