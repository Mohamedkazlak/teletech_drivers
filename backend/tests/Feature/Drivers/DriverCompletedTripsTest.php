<?php

declare(strict_types=1);

namespace Tests\Feature\Drivers;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class DriverCompletedTripsTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_lists_completed_trips_newest_first_for_admins_only(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        $newer = $this->completed($driver, [
            'finished_at' => '2026-11-03 10:00:00',
            'going_started_at' => null,
            'total_distance_m' => null,
            'pickup_summary' => 'Gate',
            'destination_summary' => 'Plant',
            'confirmation_status' => TripConfirmationStatus::Unconfirmed,
            'driver_showed_up' => false,
        ]);
        $middle = $this->completed($driver, [
            'scheduled_at' => '2026-10-01 08:00:00',
            'going_started_at' => '2026-11-01 09:00:00',
            'finished_at' => '2026-11-01 10:00:00',
            'total_distance_m' => 1234,
            'pickup_summary' => 'HQ',
            'destination_summary' => 'Site',
            'confirmation_status' => TripConfirmationStatus::Confirmed,
            'driver_showed_up' => true,
        ]);
        $older = $this->completed($driver, [
            'finished_at' => '2026-10-01 10:00:00',
            'going_started_at' => '2026-10-01 09:00:00',
        ]);
        Trip::factory()->create([
            'driver_id' => $driver->id,
            'created_by' => $driver->id,
            'status' => TripStatus::Going,
            'finished_at' => '2026-11-08 10:00:00',
        ]);

        $this->getJson('/api/drivers/'.$driver->id.'/trips')->assertUnauthorized();

        foreach ([UserRole::Employee, UserRole::CompanyAdmin, UserRole::Driver] as $role) {
            $actor = $role === UserRole::Driver ? $driver : $this->createUserWithRole($role);
            $this->actingAs($actor, 'sanctum')
                ->getJson('/api/drivers/'.$driver->id.'/trips')
                ->assertForbidden();
        }

        $employee = $this->createUserWithRole(UserRole::Employee);
        $this->actingAsRole(UserRole::DriversAdmin)
            ->getJson('/api/drivers/'.$employee->id.'/trips')
            ->assertNotFound();

        $page = $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/drivers/'.$driver->id.'/trips?per_page=1')
            ->assertOk()
            ->assertJsonPath('meta.total', 3)
            ->assertJsonPath('meta.per_page', 1)
            ->assertJsonPath('meta.current_page', 1)
            ->assertJsonPath('meta.last_page', 3)
            ->assertJsonPath('data.0.id', $newer->id)
            ->assertJsonPath('data.0.duration_seconds', null)
            ->assertJsonPath('data.0.distance_km', 0)
            ->assertJsonPath('data.0.driver_showed_up', false)
            ->assertJsonPath('data.0.confirmation_status', 'unconfirmed')
            ->assertJsonPath('data.0.pickup_summary', 'Gate')
            ->assertJsonPath('data.0.destination_summary', 'Plant')
            ->json();

        $newer->refresh();
        $this->assertSame($newer->scheduled_at->format(DATE_ATOM), $page['data'][0]['scheduled_at']);
        $this->assertNull($page['data'][0]['going_started_at']);
        $this->assertSame($newer->finished_at->format(DATE_ATOM), $page['data'][0]['finished_at']);

        $second = $this->getJson('/api/drivers/'.$driver->id.'/trips?per_page=1&page=2')
            ->assertOk()
            ->assertJsonPath('data.0.id', $middle->id)
            ->assertJsonPath('data.0.duration_seconds', 3600)
            ->assertJsonPath('data.0.distance_km', 1.23)
            ->assertJsonPath('data.0.driver_showed_up', true)
            ->assertJsonPath('data.0.confirmation_status', 'confirmed')
            ->json();
        $middle->refresh();
        $this->assertSame($middle->going_started_at->format(DATE_ATOM), $second['data'][0]['going_started_at']);

        $this->getJson('/api/drivers/'.$driver->id.'/trips?per_page=1&page=3')
            ->assertOk()
            ->assertJsonPath('data.0.id', $older->id);

        $month = $this->getJson('/api/drivers/'.$driver->id.'/trips?period=month&date=2026-11-04')
            ->assertOk()
            ->json('data');
        $this->assertSame([$newer->id, $middle->id], array_column($month, 'id'));

        $explicitAll = $this->actingAsRole(UserRole::DriversAdmin)
            ->getJson('/api/drivers/'.$driver->id.'/trips?period=all')
            ->assertOk()
            ->json('data');
        $this->assertCount(3, $explicitAll);

        $this->getJson('/api/drivers/'.$driver->id.'/trips?period=decade')->assertStatus(422);
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
