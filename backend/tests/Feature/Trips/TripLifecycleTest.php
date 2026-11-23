<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\AttendanceSource;
use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\AttendanceLog;
use App\Models\TripRequest;
use App\Models\User;
use Illuminate\Broadcasting\BroadcastException;
use Illuminate\Contracts\Broadcasting\Broadcaster;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Broadcast;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripLifecycleTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    private const POLYLINE = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

    public function test_full_happy_path_server_timestamps_and_total_distance(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Assigned;
        $trip->save();

        Sanctum::actingAs($driver);

        $this->postJson('/api/trips/'.$trip->id.'/start', [
            'start_lat' => 30.1,
            'start_lng' => 31.2,
            'going_started_at' => '2000-01-01T00:00:00+00:00',
        ])->assertOk()
            ->assertJsonPath('status', 'going')
            ->assertJsonPath('start_lat', 30.1);

        $trip->refresh();
        $this->assertNotNull($trip->going_started_at);
        $this->assertTrue($trip->going_started_at->greaterThan(now()->subMinute()));

        $this->postJson('/api/trips/'.$trip->id.'/arrive', [
            'going_distance_m' => 1500,
            'going_route' => self::POLYLINE,
            'going_ended_at' => '2000-01-01T00:00:00+00:00',
        ])->assertOk()->assertJsonPath('status', 'at_destination');

        $this->postJson('/api/trips/'.$trip->id.'/start-return')
            ->assertOk()
            ->assertJsonPath('status', 'returning');

        $this->postJson('/api/trips/'.$trip->id.'/end', [
            'return_distance_m' => 500.4,
            'return_route' => self::POLYLINE,
            'finished_at' => '2000-01-01T00:00:00+00:00',
            'total_distance_m' => 1,
        ])->assertOk()
            ->assertJsonPath('status', 'completed')
            ->assertJsonPath('return_distance_m', 500)
            ->assertJsonPath('total_distance_m', 2000);

        $trip->refresh();
        $this->assertNotNull($trip->finished_at);
        $this->assertTrue($trip->finished_at->year >= 2025);
        $this->assertSame(2000, $trip->total_distance_m);
    }

    public function test_invalid_transitions_return_409(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Assigned;
        $trip->save();

        Sanctum::actingAs($driver);
        $this->postJson('/api/trips/'.$trip->id.'/arrive', [
            'going_distance_m' => 1,
            'going_route' => self::POLYLINE,
        ])->assertStatus(409);

        $this->postJson('/api/trips/'.$trip->id.'/start', [
            'start_lat' => 1,
            'start_lng' => 1,
        ])->assertOk();

        $this->postJson('/api/trips/'.$trip->id.'/end', [
            'return_distance_m' => 1,
            'return_route' => self::POLYLINE,
        ])->assertStatus(409);
    }

    public function test_wrong_driver_forbidden(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $owner = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $owner->id;
        $trip->status = TripStatus::Assigned;
        $trip->save();

        Sanctum::actingAs($other);
        $this->postJson('/api/trips/'.$trip->id.'/start', [
            'start_lat' => 1,
            'start_lng' => 1,
        ])->assertForbidden();
    }

    public function test_lifecycle_role_matrix(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Assigned;
        $trip->save();

        foreach ([UserRole::Employee, UserRole::CompanyAdmin, UserRole::Admin, UserRole::DriversAdmin] as $role) {
            $this->actingAsRole($role)
                ->postJson('/api/trips/'.$trip->id.'/start', [
                    'start_lat' => 1,
                    'start_lng' => 1,
                ])
                ->assertForbidden();
        }

        $this->app['auth']->forgetGuards();
        $this->postJson('/api/trips/'.$trip->id.'/start', [
            'start_lat' => 1,
            'start_lng' => 1,
        ])->assertUnauthorized();
    }

    public function test_report_roles_and_partial(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Going;
        $trip->going_started_at = now();
        $trip->save();

        Sanctum::actingAs($driver);
        $this->getJson('/api/trips/'.$trip->id.'/report')
            ->assertOk()
            ->assertJsonPath('status', 'going')
            ->assertJsonPath('going_duration_seconds', null)
            ->assertJsonPath('driven_route', []);

        Sanctum::actingAs($admin);
        $this->getJson('/api/trips/'.$trip->id.'/report')->assertOk();

        foreach ([UserRole::CompanyAdmin, UserRole::Admin] as $role) {
            $this->actingAsRole($role)
                ->getJson('/api/trips/'.$trip->id.'/report')
                ->assertOk()
                ->assertJsonPath('driven_route', []);
        }

        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/trips/'.$trip->id.'/report')
            ->assertForbidden();
    }

    public function test_driver_recommendations_role_and_status(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $trip = $this->createUnassignedTrip($admin);

        Sanctum::actingAs($admin);
        $this->getJson('/api/trips/'.$trip->id.'/driver-recommendations')
            ->assertOk()
            ->assertJsonStructure(['data']);

        $trip->status = TripStatus::Going;
        $trip->save();
        $this->getJson('/api/trips/'.$trip->id.'/driver-recommendations')->assertStatus(409);

        $this->actingAsRole(UserRole::Driver)
            ->getJson('/api/trips/'.$trip->id.'/driver-recommendations')
            ->assertForbidden();
    }

    public function test_driver_recommendations_expose_is_on_active_trip(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $target = $this->createUnassignedTrip($admin);
        $target->scheduled_at = now()->addDay();
        $target->save();

        $idle = $this->createUserWithRole(UserRole::Driver);
        $this->checkIn($idle);

        $cases = [
            [TripStatus::Going, true],
            [TripStatus::AtDestination, true],
            [TripStatus::Returning, true],
            [TripStatus::Assigned, false],
        ];

        /** @var array<string, bool> $expected */
        $expected = [];
        foreach ($cases as [$status, $onActiveTrip]) {
            $driver = $this->createUserWithRole(UserRole::Driver);
            $this->checkIn($driver);

            $other = $this->createUnassignedTrip($admin);
            $other->driver_id = $driver->id;
            $other->status = $status;
            $other->scheduled_at = now()->addDays(10);
            $other->going_started_at = $onActiveTrip ? now() : null;
            $other->save();

            $expected[$driver->id] = $onActiveTrip;
        }

        Sanctum::actingAs($admin);
        $rows = collect($this->getJson('/api/trips/'.$target->id.'/driver-recommendations')
            ->assertOk()
            ->json('data'))->keyBy('driver.id');

        $this->assertFalse($rows[$idle->id]['is_on_active_trip']);
        $this->assertFalse($rows[$idle->id]['has_conflict']);
        $this->assertFalse($rows[$idle->id]['needs_confirmation']);
        $this->assertFalse($rows[$idle->id]['is_unavailable']);
        $this->assertSame(1, $rows[$idle->id]['tier']);

        foreach ($expected as $driverId => $onActiveTrip) {
            $this->assertSame($onActiveTrip, $rows[$driverId]['is_on_active_trip']);
            $this->assertSame($onActiveTrip, $rows[$driverId]['has_conflict']);
            $this->assertSame($onActiveTrip, $rows[$driverId]['needs_confirmation']);
            $this->assertSame($onActiveTrip, $rows[$driverId]['is_unavailable']);
            $this->assertSame($onActiveTrip ? 2 : 1, $rows[$driverId]['tier']);
        }

        foreach ([UserRole::CompanyAdmin, UserRole::Admin, UserRole::Employee, UserRole::Driver] as $role) {
            $this->actingAsRole($role)
                ->getJson('/api/trips/'.$target->id.'/driver-recommendations')
                ->assertForbidden();
        }
    }

    public function test_active_trip_clears_derived_availability_and_does_not_rewrite_attendance(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $this->checkIn($driver);

        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Assigned;
        $trip->save();

        Sanctum::actingAs($driver);
        $this->getJson('/api/auth/me')->assertOk()->assertJsonPath('is_available', true);

        $this->postJson('/api/trips/'.$trip->id.'/start', [
            'start_lat' => 30.1,
            'start_lng' => 31.2,
        ])->assertOk();

        $this->getJson('/api/auth/me')->assertOk()->assertJsonPath('is_available', false);
        $this->assertSame(1, AttendanceLog::query()->where('driver_id', $driver->id)->count());
        $this->assertNull(AttendanceLog::query()->where('driver_id', $driver->id)->value('checked_out_at'));

        $this->finishStartedTrip($trip->id);

        $this->getJson('/api/auth/me')->assertOk()->assertJsonPath('is_available', true);
        $this->assertSame(1, AttendanceLog::query()->where('driver_id', $driver->id)->count());
    }

    public function test_assigned_going_returning_end_completes_with_an_empty_return_route(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $employee = $this->createUserWithRole(UserRole::Employee);

        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Assigned;
        $trip->save();

        $request = TripRequest::factory()->approved()->create([
            'employee_id' => $employee->id,
            'requester_role' => UserRole::Employee,
            'trip_id' => $trip->id,
        ]);

        Sanctum::actingAs($driver);

        $this->postJson('/api/trips/'.$trip->id.'/start', [
            'start_lat' => 30.1,
            'start_lng' => 31.2,
        ])->assertOk()->assertJsonPath('status', 'going');

        $this->postJson('/api/trips/'.$trip->id.'/arrive', [
            'going_distance_m' => 1000,
            'going_route' => self::POLYLINE,
        ])->assertOk()->assertJsonPath('status', 'at_destination');

        $this->postJson('/api/trips/'.$trip->id.'/start-return')
            ->assertOk()
            ->assertJsonPath('status', 'returning');

        // The driver app sends this when no return GPS samples were accepted.
        // End does not require coordinates.
        $this->postJson('/api/trips/'.$trip->id.'/end', [
            'return_distance_m' => 0,
            'return_route' => '',
        ])->assertOk()
            ->assertJsonPath('status', 'completed')
            ->assertJsonPath('return_distance_m', 0)
            ->assertJsonPath('total_distance_m', 1000)
            ->assertJsonPath('return_route', '')
            ->assertJsonPath('confirmation_status', 'pending');

        $trip->refresh();
        $this->assertSame(TripStatus::Completed, $trip->status);
        $this->assertNotNull($trip->going_started_at);
        $this->assertNotNull($trip->finished_at);
        $this->assertSame(1000, $trip->total_distance_m);
        $this->assertSame('', $trip->return_route);
        $this->assertSame(TripConfirmationStatus::Pending, $trip->confirmation_status);
        $this->assertNotNull($trip->confirmation_requested_at);

        $this->getJson('/api/trips/'.$trip->id.'/report')
            ->assertOk()
            ->assertJsonPath('status', 'completed')
            ->assertJsonPath('is_in_progress', false)
            ->assertJsonPath('going_distance_km', 1)
            ->assertJsonPath('return_distance_km', 0)
            ->assertJsonPath('total_distance_km', 1)
            ->assertJsonPath('return_route', '');

        $report = $this->getJson('/api/trips/'.$trip->id.'/report')->json();
        $this->assertNotNull($report['start']);
        $this->assertNotNull($report['finish']);
        $this->assertIsInt($report['going_duration_seconds']);
        $this->assertIsInt($report['return_duration_seconds']);
        $this->assertIsInt($report['total_duration_seconds']);
        $this->assertGreaterThanOrEqual(0, $report['total_duration_seconds']);

        Sanctum::actingAs($employee);
        $awaiting = collect($this->getJson('/api/trip-requests/mine?awaiting_confirmation=true')
            ->assertOk()
            ->json('data'))->pluck('id');
        $this->assertTrue($awaiting->contains($request->id));
    }

    public function test_end_failure_names_the_phase_or_the_invalid_route(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Going;
        $trip->save();

        Sanctum::actingAs($driver);

        $this->postJson('/api/trips/'.$trip->id.'/end', [
            'return_distance_m' => 0,
            'return_route' => self::POLYLINE,
        ])->assertStatus(409)
            ->assertJsonPath('message', 'Trip status cannot transition from going to completed.');

        $trip->refresh();
        $this->assertSame(TripStatus::Going, $trip->status);
        $this->assertNull($trip->confirmation_status);

        $trip->status = TripStatus::Returning;
        $trip->save();

        $missing = $this->postJson('/api/trips/'.$trip->id.'/end', [
            'return_distance_m' => 0,
        ])->assertStatus(422);
        $missing->assertJsonStructure(['message', 'errors' => ['return_route']]);

        $invalid = $this->postJson('/api/trips/'.$trip->id.'/end', [
            'return_distance_m' => 0,
            'return_route' => 'not a polyline',
        ])->assertStatus(422);
        $invalid->assertJsonStructure(['message', 'errors' => ['return_route']]);
        $this->assertNotSame('', $invalid->json('message'));

        $trip->refresh();
        $this->assertSame(TripStatus::Returning, $trip->status);
    }

    public function test_driver_lifecycle_from_check_in_through_employee_confirmation(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $employee = $this->createUserWithRole(UserRole::Employee);
        $trip = $this->createUnassignedTrip($admin);
        $request = $this->createPendingRequest($employee);
        $request->status = TripRequestStatus::Approved;
        $request->trip_id = $trip->id;
        $request->save();

        $this->checkIn($driver);
        Sanctum::actingAs($driver);
        $this->getJson('/api/auth/me')->assertOk()->assertJsonPath('is_available', true);

        Sanctum::actingAs($admin);

        $this->postJson('/api/trips/'.$trip->id.'/assign', ['driver_id' => $driver->id])
            ->assertOk()
            ->assertJsonPath('status', 'assigned')
            ->assertJsonPath('driver_id', $driver->id);

        Sanctum::actingAs($driver);
        $this->getJson('/api/trips/mine?status=assigned')
            ->assertOk()
            ->assertJsonFragment([
                'id' => $trip->id,
                'status' => 'assigned',
                'pickup_summary' => $trip->pickup_summary,
                'destination_summary' => $trip->destination_summary,
            ]);

        $this->postJson('/api/trips/'.$trip->id.'/start', [
            'start_lat' => 30.05,
            'start_lng' => 31.24,
        ])->assertOk()
            ->assertJsonPath('status', 'going')
            ->assertJsonPath('start_lat', 30.05)
            ->assertJsonPath('start_lng', 31.24);

        $this->getJson('/api/auth/me')->assertOk()->assertJsonPath('is_available', false);

        Sanctum::actingAs($admin);
        $this->assertContains(
            $trip->id,
            collect($this->getJson('/api/trips?lifecycle=in_progress')->assertOk()->json('data'))->pluck('id')->all(),
        );

        Sanctum::actingAs($driver);
        $this->postJson('/api/trips/'.$trip->id.'/arrive', [
            'going_distance_m' => 1200,
            'going_route' => self::POLYLINE,
        ])->assertOk()->assertJsonPath('status', 'at_destination');

        $this->postJson('/api/trips/'.$trip->id.'/start-return')
            ->assertOk()
            ->assertJsonPath('status', 'returning');

        $this->postJson('/api/trips/'.$trip->id.'/end', [
            'return_distance_m' => 800,
            'return_route' => self::POLYLINE,
        ])->assertOk()
            ->assertJsonPath('status', 'completed')
            ->assertJsonPath('total_distance_m', 2000);

        $trip->refresh();
        $this->assertNotNull($trip->finished_at);
        $this->assertSame(2000, $trip->total_distance_m);
        $this->assertSame(TripConfirmationStatus::Pending, $trip->confirmation_status);

        Sanctum::actingAs($driver);
        $this->getJson('/api/auth/me')->assertOk()->assertJsonPath('is_available', true);

        $this->getJson('/api/trips/'.$trip->id.'/report')
            ->assertOk()
            ->assertJsonPath('status', 'completed')
            ->assertJsonPath('total_distance_km', 2);

        Sanctum::actingAs($employee);
        $this->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
            'driver_showed_up' => true,
            'note' => 'On time',
        ])->assertOk();

        $trip->refresh();
        $this->assertSame(TripConfirmationStatus::Confirmed, $trip->confirmation_status);
        $this->assertTrue($trip->driver_showed_up);
        $this->assertSame('On time', $trip->confirmation_note);

        Sanctum::actingAs($driver);
        $this->assertContains(
            $trip->id,
            collect($this->getJson('/api/trips/mine?status=completed')->assertOk()->json('data'))->pluck('id')->all(),
        );
        $this->getJson('/api/auth/me/stats?period=all')
            ->assertOk()
            ->assertJsonPath('trips', 1);

        Sanctum::actingAs($admin);
        $this->assertContains(
            $trip->id,
            collect($this->getJson('/api/trips?lifecycle=completed')->assertOk()->json('data'))->pluck('id')->all(),
        );
    }

    public function test_start_rejects_bad_location_wrong_driver_and_a_trip_that_is_not_assigned(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);

        Sanctum::actingAs($driver);
        $this->postJson('/api/trips/'.$trip->id.'/start', [
            'start_lat' => 30,
            'start_lng' => 31,
        ])->assertForbidden();

        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Assigned;
        $trip->save();

        $this->postJson('/api/trips/'.$trip->id.'/start', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['start_lat', 'start_lng']);

        Sanctum::actingAs($other);
        $this->postJson('/api/trips/'.$trip->id.'/start', [
            'start_lat' => 30,
            'start_lng' => 31,
        ])->assertForbidden();

        Sanctum::actingAs($driver);
        $this->postJson('/api/trips/'.$trip->id.'/end', [
            'return_distance_m' => 1,
            'return_route' => '',
        ])->assertStatus(409);

        $this->postJson('/api/trips/'.$trip->id.'/arrive', [
            'going_distance_m' => 0,
            'going_route' => '',
        ])->assertStatus(409);
    }

    public function test_start_and_end_succeed_when_the_socket_server_is_down(): void
    {
        Broadcast::extend('failing', function () {
            return new class implements Broadcaster
            {
                public function auth($request): mixed
                {
                    return true;
                }

                public function validAuthenticationResponse($request, $result): mixed
                {
                    return ['ok' => true];
                }

                public function broadcast(array $channels, $event, array $payload = []): void
                {
                    throw new BroadcastException('cURL error 7: Failed to connect to 127.0.0.1:8080');
                }
            };
        });
        config(['broadcasting.default' => 'failing']);

        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Assigned;
        $trip->save();

        Sanctum::actingAs($driver);
        $this->postJson('/api/trips/'.$trip->id.'/start', [
            'start_lat' => 30.1,
            'start_lng' => 31.2,
        ])->assertOk()->assertJsonPath('status', 'going');

        $this->postJson('/api/trips/'.$trip->id.'/arrive', [
            'going_distance_m' => 10,
            'going_route' => '',
        ])->assertOk()->assertJsonPath('status', 'at_destination');

        $this->postJson('/api/trips/'.$trip->id.'/start-return')->assertOk();
        $this->postJson('/api/trips/'.$trip->id.'/end', [
            'return_distance_m' => 0,
            'return_route' => '',
        ])->assertOk()->assertJsonPath('status', 'completed');
    }

    private function checkIn(User $driver): void
    {
        AttendanceLog::query()->create([
            'driver_id' => $driver->id,
            'work_date' => now()->timezone('Africa/Cairo')->toDateString(),
            'checked_in_at' => now(),
            'check_in_lat' => 30.0444,
            'check_in_lng' => 31.2357,
            'check_in_accuracy_m' => 10,
            'check_in_distance_m' => 0,
            'source' => AttendanceSource::Scan,
        ]);
    }

    private function finishStartedTrip(string $tripId): void
    {
        $this->postJson('/api/trips/'.$tripId.'/arrive', [
            'going_distance_m' => 100,
            'going_route' => self::POLYLINE,
        ])->assertOk();

        $this->postJson('/api/trips/'.$tripId.'/start-return')->assertOk();

        $this->postJson('/api/trips/'.$tripId.'/end', [
            'return_distance_m' => 40,
            'return_route' => self::POLYLINE,
        ])->assertOk()->assertJsonPath('status', 'completed');
    }
}
