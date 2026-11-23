<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class EndTripConfirmationTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    private const POLYLINE = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

    public function test_ending_a_trip_requests_confirmation_and_keeps_completed(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Returning;
        $trip->going_distance_m = 100;
        $trip->save();

        $this->assertNull($trip->confirmation_status);
        $this->assertNull($trip->confirmation_requested_at);

        Sanctum::actingAs($driver);

        try {
            Carbon::setTestNow('2026-11-04 15:00:00');

            $this->postJson('/api/trips/'.$trip->id.'/end', [
                'return_distance_m' => 40,
                'return_route' => self::POLYLINE,
            ])->assertOk()
                ->assertJsonPath('status', 'completed')
                ->assertJsonPath('confirmation_status', 'pending')
                ->assertJsonPath('confirmation_requested_at', '2026-11-04T15:00:00+00:00')
                ->assertJsonPath('confirmed_at', null)
                ->assertJsonPath('driver_showed_up', null)
                ->assertJsonPath('confirmation_note', null);
        } finally {
            Carbon::setTestNow();
        }

        $trip->refresh();
        $this->assertSame(TripStatus::Completed, $trip->status);
        $this->assertSame(TripConfirmationStatus::Pending, $trip->confirmation_status);
        $this->assertNotNull($trip->confirmation_requested_at);
        $this->assertTrue($trip->confirmation_requested_at->equalTo(Carbon::parse('2026-11-04 15:00:00')));
        $this->assertNull($trip->confirmed_at);
        $this->assertNull($trip->confirmed_by);
    }

    public function test_a_rejected_end_does_not_request_confirmation(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Assigned;
        $trip->save();

        Sanctum::actingAs($driver);
        $this->postJson('/api/trips/'.$trip->id.'/end', [
            'return_distance_m' => 40,
            'return_route' => self::POLYLINE,
        ])->assertStatus(409);

        $trip->refresh();
        $this->assertSame(TripStatus::Assigned, $trip->status);
        $this->assertNull($trip->confirmation_status);
        $this->assertNull($trip->confirmation_requested_at);
    }
}
