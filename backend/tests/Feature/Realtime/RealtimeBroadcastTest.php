<?php

declare(strict_types=1);

namespace Tests\Feature\Realtime;

use App\Broadcasting\RealtimeChannels;
use App\Domain\Enums\UserRole;
use App\Events\DriverLocationBroadcast;
use App\Events\FleetBroadcast;
use Illuminate\Broadcasting\BroadcastManager;
use Illuminate\Contracts\Broadcasting\Broadcaster;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Event;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class RealtimeBroadcastTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Event::fake([
            FleetBroadcast::class,
            DriverLocationBroadcast::class,
        ]);
    }

    public function test_employee_request_is_broadcast_to_staff_and_the_employee(): void
    {
        $this->actingAsRole(UserRole::Employee)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated();

        Event::assertDispatched(FleetBroadcast::class, function (FleetBroadcast $event): bool {
            return $event->eventName === 'trip-request.created'
                && $event->status === 'pending'
                && $event->afterCommit === true
                && $event->broadcastAs() === 'trip-request.created'
                && $event->broadcastWith() === ['id' => $event->id, 'status' => 'pending']
                && $this->hasChannels($event, [
                    'private-role.admin',
                    'private-role.company-admin',
                    'private-role.drivers-admin',
                    'private-user.'.$this->actingUser?->id,
                ]);
        });
    }

    public function test_drivers_admin_create_also_broadcasts_the_unassigned_trip(): void
    {
        $this->actingAsRole(UserRole::DriversAdmin)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated();

        Event::assertDispatched(FleetBroadcast::class, function (FleetBroadcast $event): bool {
            return $event->eventName === 'trip.created'
                && $event->status === 'unassigned'
                && $this->hasChannels($event, [
                    'private-role.admin',
                    'private-role.company-admin',
                    'private-role.drivers-admin',
                ]);
        });
    }

    public function test_approval_is_broadcast_on_the_company_admin_channel(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $request = $this->createPendingRequest($employee);

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests/'.$request->id.'/approve')
            ->assertOk();

        Event::assertDispatched(FleetBroadcast::class, function (FleetBroadcast $event) use ($employee, $request): bool {
            return $event->eventName === 'trip-request.approved'
                && $event->id === $request->id
                && $event->status === 'approved'
                && $this->hasChannels($event, [
                    'private-role.company-admin',
                    'private-user.'.$employee->id,
                ]);
        });
    }

    public function test_attendance_check_in_reaches_the_driver_and_drivers_admin(): void
    {
        config([
            'attendance.hq_lat' => 30.0444,
            'attendance.hq_lng' => 31.2357,
            'attendance.radius_m' => 150,
            'attendance.max_accuracy_m' => 50,
            'attendance.qr_secret' => 'test-secret',
            'attendance.qr_version' => 1,
        ]);

        $this->actingAsRole(UserRole::Driver)
            ->postJson('/api/attendance/check-in', [
                'qr_payload' => app(\App\Domain\Services\AttendanceQr::class)->payload(),
                'lat' => 30.0444,
                'lng' => 31.2357,
                'accuracy_m' => 10,
                'is_mocked' => false,
            ])
            ->assertCreated();

        Event::assertDispatched(FleetBroadcast::class, function (FleetBroadcast $event): bool {
            return $event->eventName === 'attendance.checked_in'
                && $event->status === 'checked_in'
                && $event->audience === 'attendance'
                && $this->hasChannels($event, [
                    'private-role.admin',
                    'private-role.drivers-admin',
                    'private-user.'.$this->actingUser?->id,
                ])
                && ! in_array('private-role.company-admin', RealtimeChannels::names($event->broadcastOn()), true);
        });
    }

    public function test_driver_location_is_broadcast_to_the_live_map_channels(): void
    {
        $this->actingAsRole(UserRole::Driver)
            ->putJson('/api/driver-location', [
                'lat' => 30.1,
                'lng' => 31.2,
                'heading' => 90,
                'speed' => 5,
                'accuracy' => 20,
                'is_tracking' => true,
            ])
            ->assertOk();

        Event::assertDispatched(DriverLocationBroadcast::class, function (DriverLocationBroadcast $event): bool {
            $payload = $event->broadcastWith();

            return $event->broadcastAs() === 'driver-location.updated'
                && $event->afterCommit === true
                && $payload['id'] === $this->actingUser?->id
                && $payload['status'] === 'tracking'
                && $payload['trip_id'] === null
                && abs($payload['lat'] - 30.1) < 0.000_001
                && abs($payload['lng'] - 31.2) < 0.000_001
                && RealtimeChannels::names($event->broadcastOn()) === [
                    'private-role.admin',
                    'private-role.drivers-admin',
                ];
        });
    }

    public function test_channel_authorization_follows_the_role(): void
    {
        // The suite broadcasts through the null driver. Channel callbacks are
        // stored on that driver, so the auth check needs a fresh Reverb driver.
        config(['broadcasting.default' => 'reverb']);
        $this->app->forgetInstance(BroadcastManager::class);
        $this->app->forgetInstance(Broadcaster::class);
        Broadcast::clearResolvedInstances();
        require base_path('routes/channels.php');

        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);

        $this->actingAs($companyAdmin, 'sanctum')
            ->postJson('/api/broadcasting/auth', [
                'socket_id' => '1234.5678',
                'channel_name' => 'private-role.company-admin',
            ])
            ->assertOk()
            ->assertJsonStructure(['auth']);

        $this->actingAs($driver, 'sanctum')
            ->postJson('/api/broadcasting/auth', [
                'socket_id' => '1234.5678',
                'channel_name' => 'private-role.company-admin',
            ])
            ->assertForbidden();

        $this->actingAs($driver, 'sanctum')
            ->postJson('/api/broadcasting/auth', [
                'socket_id' => '1234.5678',
                'channel_name' => 'private-user.'.$driver->id,
            ])
            ->assertOk();

        $this->actingAs($driver, 'sanctum')
            ->postJson('/api/broadcasting/auth', [
                'socket_id' => '1234.5678',
                'channel_name' => 'private-user.'.$companyAdmin->id,
            ])
            ->assertForbidden();
    }

    /**
     * @param  list<string>  $expected
     */
    private function hasChannels(FleetBroadcast $event, array $expected): bool
    {
        $names = RealtimeChannels::names($event->broadcastOn());
        foreach ($expected as $channel) {
            if (! in_array($channel, $names, true)) {
                return false;
            }
        }

        return true;
    }
}
