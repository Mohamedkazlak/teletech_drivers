<?php

declare(strict_types=1);

namespace Tests\Feature\Drivers;

use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class DriverTripsThisWeekTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_trips_this_week_follows_driver_list_roles(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);

        $this->getJson('/api/drivers')->assertUnauthorized();
        $this->getJson('/api/drivers/'.$driver->id)->assertUnauthorized();

        foreach ([UserRole::Admin, UserRole::DriversAdmin, UserRole::CompanyAdmin] as $role) {
            $listed = $this->actingAsRole($role)->getJson('/api/drivers')->assertOk();
            $this->assertArrayHasKey('trips_this_week', $listed->json('data.0'));

            $shown = $this->getJson('/api/drivers/'.$driver->id)->assertOk();
            $this->assertArrayHasKey('trips_this_week', $shown->json());
        }

        foreach ([UserRole::Driver, UserRole::Employee] as $role) {
            $this->actingAsRole($role)->getJson('/api/drivers')->assertForbidden();
            $this->actingAsRole($role)->getJson('/api/drivers/'.$driver->id)->assertForbidden();
        }
    }

    public function test_list_counts_the_saturday_week_in_one_grouped_query(): void
    {
        $this->travelTo(Carbon::parse('2026-11-10 12:00:00', 'Africa/Cairo'));

        $busy = $this->createUserWithRole(UserRole::Driver);
        $quiet = $this->createUserWithRole(UserRole::Driver);
        $idle = $this->createUserWithRole(UserRole::Driver);

        $this->trip($busy, TripStatus::Assigned, '2026-11-07 00:00:00');
        $this->trip($busy, TripStatus::Completed, '2026-11-10 12:00:00');
        $this->trip($busy, TripStatus::Going, '2026-11-06 22:30:00', utc: true);
        $this->trip($busy, TripStatus::Cancelled, '2026-11-10 15:00:00');
        $this->trip($quiet, TripStatus::Assigned, '2026-11-06 23:00:00');
        $this->trip($quiet, TripStatus::Returning, '2026-11-14 00:00:00');
        $this->trip($idle, TripStatus::Cancelled, '2026-11-08 09:00:00');

        $admin = $this->createUserWithRole(UserRole::Admin);
        Sanctum::actingAs($admin);

        DB::flushQueryLog();
        DB::enableQueryLog();
        $listed = $this->getJson('/api/drivers?per_page=100')->assertOk();
        $tripQueries = array_values(array_filter(
            DB::getQueryLog(),
            static fn (array $query): bool => preg_match('/group by/i', $query['query']) === 1
                && preg_match('/\btrips\b/i', $query['query']) === 1,
        ));
        DB::disableQueryLog();

        $this->assertCount(1, $tripQueries);
        $sql = strtolower($tripQueries[0]['query']);
        $this->assertStringContainsString('group by', $sql);
        $this->assertStringContainsString('count(', $sql);

        $rows = collect($listed->json('data'))->keyBy('id');
        $this->assertSame(3, $rows[$busy->id]['trips_this_week']);
        $this->assertSame(0, $rows[$quiet->id]['trips_this_week']);
        $this->assertSame(0, $rows[$idle->id]['trips_this_week']);

        $this->getJson('/api/drivers/'.$busy->id)
            ->assertOk()
            ->assertJsonPath('trips_this_week', 3)
            ->assertJsonPath('national_id', 'nid');

        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        Sanctum::actingAs($companyAdmin);
        $this->getJson('/api/drivers/'.$busy->id)
            ->assertOk()
            ->assertJsonPath('trips_this_week', 3)
            ->assertJsonMissingPath('national_id');
    }

    private function trip(User $driver, TripStatus $status, string $when, bool $utc = false): void
    {
        $scheduled = $utc
            ? $when
            : Carbon::parse($when, 'Africa/Cairo')->utc()->format('Y-m-d H:i:s');

        Trip::factory()->create([
            'created_by' => $driver->id,
            'driver_id' => $driver->id,
            'status' => $status,
            'scheduled_at' => $scheduled,
        ]);
    }
}
