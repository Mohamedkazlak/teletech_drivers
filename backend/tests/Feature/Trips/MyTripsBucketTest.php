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

final class MyTripsBucketTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_each_role_uses_the_shared_trip_buckets(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        $otherDriver = $this->createUserWithRole(UserRole::Driver);
        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $otherAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $admin = $this->createUserWithRole(UserRole::Admin);
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $employee = $this->createUserWithRole(UserRole::Employee);
        $someoneElse = $this->createUserWithRole(UserRole::Employee);

        $driverTrips = $this->statusSet($driversAdmin, $driver);
        $foreignDriver = $this->trip($driversAdmin, $otherDriver, TripStatus::Going);

        $created = $this->linkedSet($driversAdmin, $driversAdmin, $driver);
        $createdByOther = $this->trip($otherAdmin, $driver, TripStatus::Going);

        $adminTrips = $this->linkedSet($admin, $driversAdmin, $driver);
        $companyTrips = $this->linkedSet($companyAdmin, $driversAdmin, $driver);
        $employeeTrips = $this->linkedSet($employee, $driversAdmin, $driver);
        $foreignEmployee = $this->linkedSet($someoneElse, $driversAdmin, $driver);

        $cases = [
            [$driver, $driverTrips, [$foreignDriver]],
            [$driversAdmin, $created, [$createdByOther]],
            [$admin, $adminTrips, [$foreignEmployee['active']]],
            [$companyAdmin, $companyTrips, [$foreignEmployee['completed']]],
            [$employee, $employeeTrips, [$foreignEmployee['cancelled']]],
        ];

        foreach ($cases as [$actor, $own, $hidden]) {
            Sanctum::actingAs($actor);

            $active = $this->ids('/api/my-trips?bucket=active&per_page=100');
            $completed = $this->ids('/api/my-trips?bucket=completed&per_page=100');
            $cancelled = $this->ids('/api/my-trips?bucket=cancelled&per_page=100');
            $all = $this->ids('/api/my-trips?bucket=all&per_page=100');
            $omitted = $this->ids('/api/my-trips?per_page=100');

            $this->assertContains($own['active'], $active);
            $this->assertNotContains($own['completed'], $active);
            $this->assertNotContains($own['cancelled'], $active);
            $this->assertSame([$own['completed']], array_values(array_intersect($completed, array_values($own))));
            $this->assertContains($own['completed'], $completed);
            $this->assertContains($own['cancelled'], $cancelled);
            $this->assertNotContains($own['active'], $completed);
            $this->assertNotContains($own['active'], $cancelled);

            foreach ($hidden as $hiddenId) {
                $this->assertNotContains($hiddenId, $all);
                $this->assertNotContains($hiddenId, $active);
            }

            $this->assertContains($own['active'], $all);
            $this->assertContains($own['completed'], $all);
            $this->assertContains($own['cancelled'], $all);
            $this->assertEqualsCanonicalizing($all, $omitted);

            $this->getJson('/api/my-trips?bucket=archived')->assertJsonValidationErrors(['bucket']);
        }
    }

    public function test_active_bucket_is_every_non_terminal_status_and_keeps_other_filters(): void
    {
        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $active = [];
        foreach ([
            TripStatus::Unassigned,
            TripStatus::Assigned,
            TripStatus::Going,
            TripStatus::AtDestination,
            TripStatus::Returning,
        ] as $status) {
            $active[] = $this->trip($driversAdmin, $driver, $status);
        }
        $completed = $this->trip($driversAdmin, $driver, TripStatus::Completed);
        $old = Trip::factory()->create([
            'created_by' => $driversAdmin->id,
            'driver_id' => $driver->id,
            'status' => TripStatus::Assigned,
            'scheduled_at' => '2020-01-01 00:00:00',
        ])->id;

        Sanctum::actingAs($driver);

        $this->assertEqualsCanonicalizing($active, $this->ids('/api/my-trips?bucket=active&date_from=2026-01-01'));
        $this->assertContains($old, $this->ids('/api/my-trips?bucket=active&per_page=100'));
        $this->assertNotContains($completed, $this->ids('/api/my-trips?bucket=active&per_page=100'));
        $this->assertNotContains($old, $this->ids('/api/my-trips?bucket=active&date_from=2026-01-01'));
        $this->assertSame(
            [$active[2]],
            $this->ids('/api/my-trips?bucket=active&status=going'),
        );

        $page = $this->getJson('/api/my-trips?bucket=active&per_page=1&page=1')
            ->assertOk()
            ->assertJsonPath('meta.total', 6)
            ->assertJsonPath('meta.per_page', 1)
            ->assertJsonCount(1, 'data');
        $this->assertContains($page->json('data.0.id'), [...$active, $old]);
    }

    /**
     * @return array{active: string, completed: string, cancelled: string}
     */
    private function statusSet(User $creator, User $driver): array
    {
        return [
            'active' => $this->trip($creator, $driver, TripStatus::Going),
            'completed' => $this->trip($creator, $driver, TripStatus::Completed),
            'cancelled' => $this->trip($creator, $driver, TripStatus::Cancelled),
        ];
    }

    /**
     * @return array{active: string, completed: string, cancelled: string}
     */
    private function linkedSet(User $requester, User $creator, User $driver): array
    {
        $set = $this->statusSet($creator, $driver);
        foreach ($set as $id) {
            TripRequest::factory()->approved()->create([
                'employee_id' => $requester->id,
                'requester_role' => $requester->role,
                'trip_id' => $id,
            ]);
        }

        return $set;
    }

    private function trip(User $creator, User $driver, TripStatus $status): string
    {
        return Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => $driver->id,
            'status' => $status,
            'scheduled_at' => '2026-11-10 10:00:00',
        ])->id;
    }

    /**
     * @return list<string>
     */
    private function ids(string $url): array
    {
        return collect($this->getJson($url)->assertOk()->json('data'))->pluck('id')->all();
    }
}
