<?php

declare(strict_types=1);

namespace Tests\Feature\DriverLocations;

use App\Domain\Enums\AttendanceSource;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\AttendanceLog;
use App\Models\DriverLocation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class DriverLocationEndpointsTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    /**
     * @return array<string, mixed>
     */
    private function body(float $accuracy = 20, ?string $tripId = null): array
    {
        return [
            'lat' => 30.1,
            'lng' => 31.2,
            'heading' => 90,
            'speed' => 5,
            'accuracy' => $accuracy,
            'is_tracking' => true,
            'trip_id' => $tripId,
        ];
    }

    public function test_role_matrix_all_endpoints(): void
    {
        $this->putJson('/api/driver-location', $this->body())->assertUnauthorized();
        $this->postJson('/api/driver-location/stop')->assertUnauthorized();
        $this->getJson('/api/live-map')->assertUnauthorized();

        foreach ([UserRole::Employee, UserRole::CompanyAdmin, UserRole::Admin, UserRole::DriversAdmin] as $role) {
            $this->actingAsRole($role)
                ->putJson('/api/driver-location', $this->body())
                ->assertForbidden();
            $this->actingAsRole($role)
                ->postJson('/api/driver-location/stop')
                ->assertForbidden();
        }

        foreach ([UserRole::Employee, UserRole::CompanyAdmin, UserRole::Driver] as $role) {
            $this->actingAsRole($role)
                ->getJson('/api/live-map')
                ->assertForbidden();
        }

        foreach ([UserRole::Admin, UserRole::DriversAdmin] as $role) {
            $this->actingAsRole($role)
                ->getJson('/api/live-map')
                ->assertOk()
                ->assertJsonStructure(['data']);
        }
    }

    public function test_system_admin_receives_the_same_live_map_payload_as_drivers_admin(): void
    {
        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $systemAdmin = $this->createUserWithRole(UserRole::Admin);
        $driver = $this->createUserWithRole(UserRole::Driver);

        Sanctum::actingAs($driver);
        $this->putJson('/api/driver-location', $this->body())->assertOk();

        Sanctum::actingAs($driversAdmin);
        $asDriversAdmin = $this->getJson('/api/live-map')->assertOk()->json();

        Sanctum::actingAs($systemAdmin);
        $asAdmin = $this->getJson('/api/live-map')->assertOk()->json();

        $this->assertSame($asDriversAdmin, $asAdmin);
        $this->assertCount(1, $asAdmin['data']);
    }

    public function test_going_and_returning_updates_show_on_the_live_map(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Going;
        $trip->going_started_at = now();
        $trip->save();

        Sanctum::actingAs($driver);
        $this->putJson('/api/driver-location', $this->body(15, $trip->id))
            ->assertOk()
            ->assertJsonPath('trip_id', $trip->id);

        Sanctum::actingAs($admin);
        $going = $this->liveRow($driver->id);
        $this->assertSame('going', $going['trip']['status']);
        $this->assertSame('on_trip', $going['state']);
        $this->assertEqualsWithDelta(30.1, $going['lat'], 0.00001);
        $this->assertEqualsWithDelta(31.2, $going['lng'], 0.00001);
        $this->assertTrue($going['is_tracking']);
        $this->assertFalse($going['is_stale']);

        Sanctum::actingAs($driver);
        $this->putJson('/api/driver-location', array_merge($this->body(15, $trip->id), [
            'lat' => 30.2,
            'lng' => 31.3,
        ]))->assertOk();

        $trip->status = TripStatus::Returning;
        $trip->save();
        $this->putJson('/api/driver-location', array_merge($this->body(18, $trip->id), [
            'lat' => 30.4,
            'lng' => 31.5,
        ]))->assertOk();

        Sanctum::actingAs($admin);
        $returning = $this->liveRow($driver->id);
        $this->assertSame('returning', $returning['trip']['status']);
        $this->assertEqualsWithDelta(30.4, $returning['lat'], 0.00001);
        $this->assertEqualsWithDelta(31.5, $returning['lng'], 0.00001);
        $this->assertTrue($returning['is_tracking']);

        Sanctum::actingAs($driver);
        $this->postJson('/api/driver-location/stop')->assertOk();

        Sanctum::actingAs($admin);
        $stopped = $this->liveRow($driver->id);
        $this->assertEqualsWithDelta(30.4, $stopped['lat'], 0.00001);
        $this->assertEqualsWithDelta(31.5, $stopped['lng'], 0.00001);
        $this->assertFalse($stopped['is_tracking']);
    }

    public function test_accuracy_first_publish_vs_later(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        Sanctum::actingAs($driver);

        $this->putJson('/api/driver-location', $this->body(400))->assertOk();
        $this->putJson('/api/driver-location', $this->body(60))->assertStatus(422);
        $this->putJson('/api/driver-location', $this->body(40))->assertOk();
    }

    public function test_stop_and_stale_boundary(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Going;
        $trip->going_started_at = now();
        $trip->save();

        Sanctum::actingAs($driver);
        $this->putJson('/api/driver-location', $this->body(20, $trip->id))->assertOk();
        $this->postJson('/api/driver-location/stop')
            ->assertOk()
            ->assertJsonPath('is_tracking', false);

        // Flutter: age > 60s is stale; age == 60s is not.
        DriverLocation::query()->whereKey($driver->id)->update([
            'updated_at' => now()->subSeconds(60),
        ]);

        Sanctum::actingAs($admin);
        $fresh = $this->getJson('/api/live-map')->assertOk()->json('data.0');
        $this->assertFalse($fresh['is_stale']);
        $this->assertSame($fresh['updated_at'], $fresh['last_seen_at']);

        DriverLocation::query()->whereKey($driver->id)->update([
            'updated_at' => now()->subSeconds(61),
        ]);
        $stale = $this->getJson('/api/live-map')->assertOk()->json('data.0');
        $this->assertTrue($stale['is_stale']);
    }

    public function test_live_map_includes_idle_drivers_and_only_in_progress_trips(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);

        $assigned = $this->createUnassignedTrip($admin);
        $assigned->driver_id = $driver->id;
        $assigned->status = TripStatus::Assigned;
        $assigned->save();

        $going = $this->createUnassignedTrip($admin);
        $going->driver_id = $driver->id;
        $going->status = TripStatus::Going;
        $going->going_started_at = now();
        $going->save();

        Sanctum::actingAs($admin);
        $rows = collect($this->getJson('/api/live-map')->assertOk()->json('data'))
            ->keyBy(static fn (array $row): string => $row['driver']['id']);
        $this->assertCount(2, $rows);
        $this->assertSame($going->id, $rows[$driver->id]['trip']['id']);
        $this->assertSame('on_trip', $rows[$driver->id]['state']);
        $this->assertNull($rows[$driver->id]['lat']);
        $this->assertNull($rows[$other->id]['trip']);
        $this->assertNull($rows[$other->id]['lat']);
        $this->assertNull($rows[$other->id]['lng']);
        $this->assertNull($rows[$other->id]['heading']);
        $this->assertNull($rows[$other->id]['speed']);
        $this->assertNull($rows[$other->id]['last_seen_at']);
        $this->assertTrue($rows[$other->id]['is_stale']);
        $this->assertFalse($rows[$other->id]['is_tracking']);
        $this->assertSame('unavailable', $rows[$other->id]['state']);
        $this->assertFalse($rows[$other->id]['is_available']);

        Sanctum::actingAs($driver);
        $this->putJson('/api/driver-location', $this->body(20, $other->id === $going->id ? $assigned->id : $going->id))
            ->assertOk();

        $foreign = $this->createUnassignedTrip($admin);
        $foreign->driver_id = $other->id;
        $foreign->status = TripStatus::Going;
        $foreign->save();

        $this->putJson('/api/driver-location', $this->body(20, $foreign->id))
            ->assertStatus(422);
    }

    public function test_live_map_trip_includes_scheduled_at_and_going_started_at(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $otherDriver = $this->createUserWithRole(UserRole::Driver);

        $started = $this->createUnassignedTrip($admin);
        $started->driver_id = $driver->id;
        $started->status = TripStatus::Going;
        $started->scheduled_at = '2026-11-04T09:00:00+00:00';
        $started->going_started_at = '2026-11-04T09:05:00+00:00';
        $started->save();

        $withoutStart = $this->createUnassignedTrip($admin);
        $withoutStart->driver_id = $otherDriver->id;
        $withoutStart->status = TripStatus::AtDestination;
        $withoutStart->scheduled_at = '2026-11-04T11:00:00+00:00';
        $withoutStart->going_started_at = null;
        $withoutStart->save();

        Sanctum::actingAs($admin);
        $rows = collect($this->getJson('/api/live-map')->assertOk()->json('data'))
            ->keyBy(static fn (array $row): string => $row['trip']['id']);

        $started->refresh();
        $withoutStart->refresh();

        $this->assertSame(
            $started->scheduled_at->format(DATE_ATOM),
            $rows[$started->id]['trip']['scheduled_at'],
        );
        $this->assertSame(
            $started->going_started_at->format(DATE_ATOM),
            $rows[$started->id]['trip']['going_started_at'],
        );
        $this->assertMatchesRegularExpression('/\+00:00$/', $rows[$started->id]['trip']['scheduled_at']);
        $this->assertSame(
            $withoutStart->scheduled_at->format(DATE_ATOM),
            $rows[$withoutStart->id]['trip']['scheduled_at'],
        );
        $this->assertNull($rows[$withoutStart->id]['trip']['going_started_at']);

        $systemAdmin = $this->createUserWithRole(UserRole::Admin);
        Sanctum::actingAs($systemAdmin);
        $asAdmin = collect($this->getJson('/api/live-map')->assertOk()->json('data'))
            ->keyBy(static fn (array $row): string => $row['trip']['id']);
        $this->assertSame(
            $rows[$started->id]['trip'],
            $asAdmin[$started->id]['trip'],
        );

        foreach ([UserRole::CompanyAdmin, UserRole::Employee, UserRole::Driver] as $role) {
            $this->actingAsRole($role)
                ->getJson('/api/live-map')
                ->assertForbidden();
        }
    }

    public function test_live_map_filters_and_skips_inactive_or_deleted_drivers(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $available = $this->createUserWithRole(UserRole::Driver);
        $this->openAttendance($available);

        $unavailable = $this->createUserWithRole(UserRole::Driver);
        $onTrip = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $onTrip->id;
        $trip->status = TripStatus::Returning;
        $trip->save();

        $inactive = $this->createUserWithRole(UserRole::Driver);
        $inactive->is_active = false;
        $inactive->save();

        $deleted = $this->createUserWithRole(UserRole::Driver);
        $deleted->delete();

        Sanctum::actingAs($admin);
        $rows = collect($this->getJson('/api/live-map')->assertOk()->json('data'))
            ->keyBy(static fn (array $row): string => $row['driver']['id']);

        $this->assertSame(['available', 'unavailable', 'on_trip'], [
            $rows[$available->id]['state'],
            $rows[$unavailable->id]['state'],
            $rows[$onTrip->id]['state'],
        ]);
        $this->assertSame($trip->id, $rows[$onTrip->id]['trip']['id']);
        $this->assertNull($rows[$available->id]['trip']);
        $this->assertArrayNotHasKey($inactive->id, $rows);
        $this->assertArrayNotHasKey($deleted->id, $rows);

        $onlyCheckedIn = $this->getJson('/api/live-map?attendance=checked_in')->assertOk()->json('data');
        $this->assertSame([$available->id], array_column(array_column($onlyCheckedIn, 'driver'), 'id'));

        $one = $this->getJson('/api/live-map?driver_id='.$unavailable->id.'&attendance=not_checked_in')
            ->assertOk()
            ->json('data');
        $this->assertCount(1, $one);
        $this->assertSame($unavailable->id, $one[0]['driver']['id']);

        $this->getJson('/api/live-map?driver_id='.$available->id.'&attendance=not_checked_in')
            ->assertOk()
            ->assertJsonPath('data', []);

        $this->getJson('/api/live-map?attendance=asleep')->assertStatus(422);
    }

    /**
     * @return array<string, mixed>
     */
    private function liveRow(string $driverId): array
    {
        $row = collect($this->getJson('/api/live-map')->assertOk()->json('data'))
            ->first(static fn (array $item): bool => $item['driver']['id'] === $driverId);
        $this->assertIsArray($row);

        return $row;
    }

    private function openAttendance(User $driver): void
    {
        AttendanceLog::query()->create([
            'driver_id' => $driver->id,
            'work_date' => now()->timezone('Africa/Cairo')->toDateString(),
            'checked_in_at' => now(),
            'source' => AttendanceSource::Scan,
        ]);
    }
}
