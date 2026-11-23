<?php

declare(strict_types=1);

namespace Tests\Feature\Drivers;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\User;
use DateTimeImmutable;
use DateTimeZone;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class DriverStatsEndpointsTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_me_stats_is_driver_only_and_applies_completed_trip_rules(): void
    {
        $this->getJson('/api/auth/me/stats?period=week&date=2026-11-04')->assertUnauthorized();

        foreach ([UserRole::Employee, UserRole::CompanyAdmin, UserRole::Admin, UserRole::DriversAdmin] as $role) {
            $this->actingAsRole($role)
                ->getJson('/api/auth/me/stats?period=week&date=2026-11-04')
                ->assertForbidden();
        }

        $driver = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);
        $this->actingAs($driver, 'sanctum');

        $this->seedWeekTrips($driver, $other);

        $body = $this->getJson('/api/auth/me/stats?period=week&date=2026-11-04')
            ->assertOk()
            ->assertJsonPath('period', 'week')
            ->assertJsonPath('trips', 3)
            ->assertJsonPath('total_seconds', 7200)
            ->assertJsonPath('total_km', 3)
            ->json();

        $cairo = new DateTimeZone('Africa/Cairo');
        $utc = new DateTimeZone('UTC');
        $this->assertSame(
            (new DateTimeImmutable('2026-10-31 00:00:00', $cairo))->setTimezone($utc)->format(DATE_ATOM),
            $body['from'],
        );
        $this->assertSame(
            (new DateTimeImmutable('2026-11-07 00:00:00', $cairo))->setTimezone($utc)->format(DATE_ATOM),
            $body['to'],
        );
        $this->assertCount(7, $body['breakdown']);
        $this->assertSame('2026-10-31', $body['breakdown'][0]['label']);
        $this->assertSame('2026-11-06', $body['breakdown'][6]['label']);

        $byLabel = collect($body['breakdown'])->keyBy('label');
        $this->assertSame(2, $byLabel['2026-11-04']['trips']);
        $this->assertSame(7200, $byLabel['2026-11-04']['total_seconds']);
        $this->assertEquals(2.5, $byLabel['2026-11-04']['total_km']);
        $this->assertSame(1, $byLabel['2026-11-05']['trips']);
        $this->assertSame(0, $byLabel['2026-11-05']['total_seconds']);
        $this->assertEquals(0.5, $byLabel['2026-11-05']['total_km']);
        $this->assertSame(0, $byLabel['2026-11-06']['trips']);
        $this->assertSame(
            (new DateTimeImmutable('2026-11-04 00:00:00', $cairo))->setTimezone($utc)->format(DATE_ATOM),
            $byLabel['2026-11-04']['from'],
        );

        $this->getJson('/api/auth/me/stats?period=nope')->assertStatus(422);
        $this->getJson('/api/auth/me/stats')->assertStatus(422);
    }

    public function test_admin_driver_stats_match_the_driver_and_reject_other_roles(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);
        $this->seedWeekTrips($driver, $other);

        $this->getJson('/api/drivers/'.$driver->id.'/stats?period=week&date=2026-11-04')
            ->assertUnauthorized();

        foreach ([UserRole::Employee, UserRole::CompanyAdmin, UserRole::Driver] as $role) {
            $actor = $role === UserRole::Driver ? $driver : $this->createUserWithRole($role);
            $this->actingAs($actor, 'sanctum')
                ->getJson('/api/drivers/'.$driver->id.'/stats?period=week&date=2026-11-04')
                ->assertForbidden();
        }

        foreach ([UserRole::Admin, UserRole::DriversAdmin] as $role) {
            $body = $this->actingAsRole($role)
                ->getJson('/api/drivers/'.$driver->id.'/stats?period=week&date=2026-11-04')
                ->assertOk()
                ->json();

            $this->assertSame(3, $body['trips']);
            $this->assertSame(7200, $body['total_seconds']);
            $this->assertEquals(3, $body['total_km']);
            $this->assertCount(7, $body['breakdown']);
        }

        $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/drivers/'.fake()->uuid().'/stats?period=week&date=2026-11-04')
            ->assertNotFound();

        $employee = $this->createUserWithRole(UserRole::Employee);
        $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/drivers/'.$employee->id.'/stats?period=all')
            ->assertNotFound();
    }

    public function test_period_shapes_and_all_ignores_the_anchor_date(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        $this->actingAs($driver, 'sanctum');

        $emptyWeek = $this->getJson('/api/auth/me/stats?period=month&date=2026-11-04')->assertOk()->json();
        $this->assertCount(30, $emptyWeek['breakdown']);
        $this->assertSame(0, $emptyWeek['trips']);

        $emptyYear = $this->getJson('/api/auth/me/stats?period=year&date=2026-11-04')->assertOk()->json();
        $this->assertCount(12, $emptyYear['breakdown']);
        $this->assertSame('2026-01', $emptyYear['breakdown'][0]['label']);
        $this->assertSame('2026-12', $emptyYear['breakdown'][11]['label']);

        $this->completed($driver, [
            'finished_at' => '2024-06-15 12:00:00',
            'going_started_at' => '2024-06-15 11:50:00',
            'total_distance_m' => 1000,
        ]);
        $this->completed($driver, [
            'finished_at' => '2026-03-01 12:00:00',
            'going_started_at' => '2026-03-01 11:00:00',
            'total_distance_m' => 2000,
        ]);
        $this->completed($driver, [
            'finished_at' => '2026-03-01 15:00:00',
            'going_started_at' => '2026-03-01 14:00:00',
            'total_distance_m' => 9000,
            'driver_showed_up' => false,
        ]);

        $all = $this->getJson('/api/auth/me/stats?period=all&date=2026-11-04')->assertOk()->json();
        $this->assertSame('all', $all['period']);
        $this->assertSame(2, $all['trips']);
        $this->assertSame(4200, $all['total_seconds']);
        $this->assertEquals(3, $all['total_km']);
        $this->assertSame(['2024', '2026'], array_column($all['breakdown'], 'label'));

        $cairo = new DateTimeZone('Africa/Cairo');
        $utc = new DateTimeZone('UTC');
        $this->assertSame(
            (new DateTimeImmutable('2024-01-01 00:00:00', $cairo))->setTimezone($utc)->format(DATE_ATOM),
            $all['from'],
        );
        $this->assertSame(
            (new DateTimeImmutable('2027-01-01 00:00:00', $cairo))->setTimezone($utc)->format(DATE_ATOM),
            $all['to'],
        );

        $none = $this->actingAsRole(UserRole::Driver)
            ->getJson('/api/auth/me/stats?period=all')
            ->assertOk()
            ->json();
        $this->assertNull($none['from']);
        $this->assertNull($none['to']);
        $this->assertSame([], $none['breakdown']);
    }

    public function test_driver_show_includes_all_time_totals_and_lists_do_not(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        $this->completed($driver, [
            'finished_at' => '2026-03-01 12:00:00',
            'going_started_at' => '2026-03-01 11:00:00',
            'total_distance_m' => 1500,
        ]);
        $this->completed($driver, [
            'finished_at' => '2026-04-01 12:00:00',
            'going_started_at' => null,
            'total_distance_m' => null,
            'driver_showed_up' => null,
        ]);
        $this->completed($driver, [
            'finished_at' => '2026-04-02 12:00:00',
            'total_distance_m' => 4000,
            'driver_showed_up' => false,
        ]);
        Trip::factory()->create([
            'driver_id' => $driver->id,
            'created_by' => $driver->id,
            'status' => TripStatus::Assigned,
            'finished_at' => '2026-04-03 12:00:00',
            'total_distance_m' => 8000,
        ]);

        $admin = $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/drivers/'.$driver->id)
            ->assertOk()
            ->assertJsonPath('national_id', 'nid')
            ->assertJsonPath('totals.trips', 2)
            ->assertJsonPath('totals.total_seconds', 3600)
            ->assertJsonPath('totals.total_km', 1.5)
            ->json();
        $this->assertArrayHasKey('totals', $admin);

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->getJson('/api/drivers/'.$driver->id)
            ->assertOk()
            ->assertJsonMissingPath('national_id')
            ->assertJsonPath('totals.trips', 2)
            ->assertJsonPath('totals.total_seconds', 3600)
            ->assertJsonPath('totals.total_km', 1.5);

        $listed = collect($this->actingAsRole(UserRole::Admin)->getJson('/api/drivers')->assertOk()->json('data'))
            ->firstWhere('id', $driver->id);
        $this->assertIsArray($listed);
        $this->assertArrayNotHasKey('totals', $listed);

        $this->actingAs($driver, 'sanctum')
            ->getJson('/api/auth/me/driver-profile')
            ->assertOk()
            ->assertJsonMissingPath('totals');
    }

    private function seedWeekTrips(User $driver, User $other): void
    {
        $this->completed($driver, [
            'scheduled_at' => '2026-10-01 08:00:00',
            'going_started_at' => '2026-11-04 09:00:00',
            'finished_at' => '2026-11-04 10:00:00',
            'total_distance_m' => 2500,
            'driver_showed_up' => true,
        ]);
        $this->completed($driver, [
            'going_started_at' => '2026-11-04 11:00:00',
            'finished_at' => '2026-11-04 12:00:00',
            'total_distance_m' => null,
            'driver_showed_up' => null,
        ]);
        $this->completed($driver, [
            'going_started_at' => null,
            'finished_at' => '2026-11-05 08:00:00',
            'total_distance_m' => 500,
            'driver_showed_up' => true,
        ]);
        $this->completed($driver, [
            'finished_at' => '2026-11-04 15:00:00',
            'total_distance_m' => 99999,
            'driver_showed_up' => false,
        ]);
        $this->completed($driver, [
            'going_started_at' => '2026-11-06 21:00:00',
            'finished_at' => '2026-11-06 22:30:00',
            'total_distance_m' => 100000,
        ]);
        $this->completed($other, [
            'finished_at' => '2026-11-04 10:00:00',
            'total_distance_m' => 100000,
        ]);
        Trip::factory()->create([
            'driver_id' => $driver->id,
            'created_by' => $driver->id,
            'status' => TripStatus::Assigned,
            'finished_at' => '2026-11-04 16:00:00',
            'total_distance_m' => 100000,
        ]);
        Trip::factory()->create([
            'driver_id' => $driver->id,
            'created_by' => $driver->id,
            'status' => TripStatus::Cancelled,
            'finished_at' => '2026-11-04 17:00:00',
            'total_distance_m' => 100000,
        ]);
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    private function completed(User $driver, array $overrides): Trip
    {
        return Trip::factory()->create(array_merge([
            'driver_id' => $driver->id,
            'created_by' => $driver->id,
            'status' => TripStatus::Completed,
            'scheduled_at' => '2026-11-04 08:00:00',
            'going_started_at' => '2026-11-04 08:00:00',
            'finished_at' => '2026-11-04 09:00:00',
            'total_distance_m' => 1000,
            'pickup_summary' => 'HQ',
            'destination_summary' => 'Site',
            'confirmation_status' => TripConfirmationStatus::Confirmed,
            'driver_showed_up' => true,
        ], $overrides));
    }
}
