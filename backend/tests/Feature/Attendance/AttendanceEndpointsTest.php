<?php

declare(strict_types=1);

namespace Tests\Feature\Attendance;

use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Services\AttendanceQr;
use App\Domain\Services\HaversineDistance;
use App\Models\AttendanceLog;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class AttendanceEndpointsTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    private const HQ_LAT = 30.0444;

    private const HQ_LNG = 31.2357;

    protected function setUp(): void
    {
        parent::setUp();
        config([
            'attendance.hq_lat' => self::HQ_LAT,
            'attendance.hq_lng' => self::HQ_LNG,
            'attendance.radius_m' => 150,
            'attendance.max_accuracy_m' => 50,
            'attendance.qr_secret' => 'test-secret',
            'attendance.qr_version' => 1,
            'attendance.weekly_off_days' => [5],
        ]);
    }

    public function test_scan_validation_order_and_error_codes(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        Sanctum::actingAs($driver);

        $this->postJson('/api/attendance/check-in', $this->body(qr: 'not-a-code', mocked: true, accuracy: 500, lat: 0))
            ->assertStatus(422)
            ->assertJsonPath('code', 'invalid_qr');

        $this->postJson('/api/attendance/check-in', $this->body(mocked: true, accuracy: 500, lat: 0))
            ->assertStatus(422)
            ->assertJsonPath('code', 'mock_location');

        $this->postJson('/api/attendance/check-in', $this->body(accuracy: 50.1, lat: 0))
            ->assertStatus(422)
            ->assertJsonPath('code', 'low_accuracy');

        $outside = $this->postJson('/api/attendance/check-in', $this->body(lat: $this->north(151)))
            ->assertStatus(422)
            ->assertJsonPath('code', 'outside_radius')
            ->assertJsonPath('radius_m', 150);
        $this->assertGreaterThan(150, $outside->json('distance_m'));

        $this->postJson('/api/attendance/check-in', $this->body(lat: $this->north(150)))
            ->assertCreated()
            ->assertJsonPath('status', 'checked_in')
            ->assertJsonPath('source', 'scan');

        $this->assertLessThanOrEqual(
            150,
            (int) AttendanceLog::query()->value('check_in_distance_m'),
        );
    }

    public function test_just_inside_the_radius_is_accepted(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        Sanctum::actingAs($driver);

        $created = $this->postJson('/api/attendance/check-in', $this->body(lat: $this->north(149)))
            ->assertCreated();

        $this->assertLessThanOrEqual(150, $created->json('check_in_distance_m'));
        $meters = (new HaversineDistance)->meters(self::HQ_LAT, self::HQ_LNG, $this->north(149), self::HQ_LNG);
        $this->assertLessThanOrEqual(150, $meters);
    }

    public function test_duplicate_check_in_and_check_out_rules(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        Sanctum::actingAs($driver);

        $this->postJson('/api/attendance/check-out', $this->body())
            ->assertStatus(409)
            ->assertJsonPath('code', 'not_checked_in');

        $this->postJson('/api/attendance/check-in', $this->body())->assertCreated();
        $this->postJson('/api/attendance/check-in', $this->body())
            ->assertStatus(409)
            ->assertJsonPath('code', 'already_checked_in');

        $this->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('status', 'checked_in');

        $trip = $this->createUnassignedTrip($admin);
        $trip->driver_id = $driver->id;
        $trip->status = TripStatus::Going;
        $trip->save();

        $this->postJson('/api/attendance/check-out', $this->body())
            ->assertStatus(409)
            ->assertJsonPath('code', 'active_trip');

        $trip->status = TripStatus::Completed;
        $trip->save();

        $this->postJson('/api/attendance/check-out', $this->body())
            ->assertOk()
            ->assertJsonPath('status', 'checked_out');
        $this->assertNotNull(AttendanceLog::query()->value('checked_out_at'));

        $this->postJson('/api/attendance/check-out', $this->body())
            ->assertStatus(409)
            ->assertJsonPath('code', 'already_checked_out');

        $this->postJson('/api/attendance/check-in', $this->body())
            ->assertStatus(409)
            ->assertJsonPath('code', 'already_checked_in');
    }

    public function test_forgotten_check_out_stays_null(): void
    {
        $this->travelTo(Carbon::parse('2026-11-18 18:00:00', 'Africa/Cairo'));
        $driver = $this->createUserWithRole(UserRole::Driver);
        Sanctum::actingAs($driver);
        $this->postJson('/api/attendance/check-in', $this->body())->assertCreated();

        $this->travelTo(Carbon::parse('2026-11-19 09:00:00', 'Africa/Cairo'));
        $this->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('status', 'not_checked_in')
            ->assertJsonPath('attendance', null);

        $yesterday = AttendanceLog::query()->first();
        $this->assertNotNull($yesterday);
        $this->assertNull($yesterday->checked_out_at);
        $this->assertSame('checked_in', $yesterday->status());
    }

    public function test_absent_days_skip_off_days_creation_and_the_future(): void
    {
        $this->travelTo(Carbon::parse('2026-11-18 12:00:00', 'Africa/Cairo'));
        $driver = $this->createUserWithRole(UserRole::Driver);
        $driver->created_at = Carbon::parse('2026-11-16 08:00:00', 'Africa/Cairo');
        $driver->save();

        AttendanceLog::query()->create([
            'driver_id' => $driver->id,
            'work_date' => '2026-11-17',
            'checked_in_at' => Carbon::parse('2026-11-17 08:00:00', 'Africa/Cairo'),
            'checked_out_at' => Carbon::parse('2026-11-17 16:00:00', 'Africa/Cairo'),
            'source' => 'scan',
        ]);

        Sanctum::actingAs($driver);
        $rows = collect($this->getJson('/api/attendance/me?period=week&date=2026-11-18')
            ->assertOk()
            ->json('data'))->keyBy('work_date');

        $this->assertArrayNotHasKey('2026-11-14', $rows->all());
        $this->assertArrayNotHasKey('2026-11-15', $rows->all());
        $this->assertArrayNotHasKey('2026-11-20', $rows->all());
        $this->assertSame('absent', $rows['2026-11-16']['status']);
        $this->assertSame('checked_out', $rows['2026-11-17']['status']);
        $this->assertEquals(8, $rows['2026-11-17']['on_site_hours']);
        $this->assertSame('absent', $rows['2026-11-18']['status']);
        $this->assertSame(1, $this->getJson('/api/attendance/me?period=week&date=2026-11-18')->json('totals.days_present'));
        $this->assertSame(2, $this->getJson('/api/attendance/me?period=week&date=2026-11-18')->json('totals.days_absent'));
    }

    public function test_role_matrix_summary_adjust_and_qr(): void
    {
        $this->getJson('/api/attendance')->assertUnauthorized();

        foreach ([UserRole::Employee, UserRole::CompanyAdmin, UserRole::Driver] as $role) {
            $this->actingAsRole($role)->getJson('/api/attendance')->assertForbidden();
            $this->actingAsRole($role)->getJson('/api/attendance/qr')->assertForbidden();
            $this->actingAsRole($role)->getJson('/api/attendance/today/summary')->assertForbidden();
        }

        foreach ([UserRole::Employee, UserRole::CompanyAdmin, UserRole::Admin, UserRole::DriversAdmin] as $role) {
            $this->actingAsRole($role)
                ->postJson('/api/attendance/check-in', $this->body())
                ->assertForbidden();
        }

        $driver = $this->createUserWithRole(UserRole::Driver);
        Sanctum::actingAs($driver);
        $this->getJson('/api/attendance/today')->assertOk()->assertJsonPath('status', 'not_checked_in');

        $payload = $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/attendance/qr')
            ->assertOk()
            ->json('payload');
        $this->assertSame(app(AttendanceQr::class)->payload(), $payload);

        $this->actingAsRole(UserRole::DriversAdmin)
            ->postJson('/api/attendance/adjust', [
                'driver_id' => $driver->id,
                'work_date' => '2026-11-16',
                'checked_in_at' => '2026-11-16T08:00:00+02:00',
                'checked_out_at' => '2026-11-16T17:00:00+02:00',
                'reason' => 'Gate log was missed',
            ])
            ->assertCreated()
            ->assertJsonPath('source', 'admin')
            ->assertJsonPath('adjustment_reason', 'Gate log was missed');

        $this->actingAsRole(UserRole::Employee)
            ->postJson('/api/attendance/adjust', [
                'driver_id' => $driver->id,
                'work_date' => '2026-11-16',
                'checked_in_at' => '2026-11-16T08:00:00+02:00',
                'reason' => 'no',
            ])
            ->assertForbidden();

        $history = $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/drivers/'.$driver->id.'/attendance?date_from=2026-11-16&date_to=2026-11-16')
            ->assertOk()
            ->json();
        $this->assertSame(1, $history['totals']['days_present']);
        $this->assertEquals(9, $history['totals']['total_on_site_hours']);

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->getJson('/api/drivers/'.$driver->id.'/attendance')
            ->assertForbidden();
    }

    public function test_derived_availability_orders_assignment_candidates(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $near = $this->createUserWithRole(UserRole::Driver);
        $near->name_en = 'Zoe';
        $near->save();
        $far = $this->createUserWithRole(UserRole::Driver);
        $far->name_en = 'Amy';
        $far->save();
        $absent = $this->createUserWithRole(UserRole::Driver);
        $absent->name_en = 'Ben';
        $absent->save();

        $today = now()->timezone('Africa/Cairo')->toDateString();
        AttendanceLog::query()->create([
            'driver_id' => $near->id,
            'work_date' => $today,
            'checked_in_at' => now(),
            'check_in_distance_m' => 20,
            'source' => 'scan',
        ]);
        AttendanceLog::query()->create([
            'driver_id' => $far->id,
            'work_date' => $today,
            'checked_in_at' => now(),
            'check_in_distance_m' => 800,
            'source' => 'scan',
        ]);

        $trip = $this->createUnassignedTrip($admin);
        Sanctum::actingAs($admin);
        $ids = collect($this->getJson('/api/trips/'.$trip->id.'/driver-recommendations')->assertOk()->json('data'))
            ->pluck('driver.id')
            ->all();

        $this->assertSame([$near->id, $far->id], array_slice($ids, 0, 2));
        $rows = collect($this->getJson('/api/trips/'.$trip->id.'/driver-recommendations')->json('data'))
            ->keyBy('driver.id');
        $this->assertFalse($rows[$near->id]['is_unavailable']);
        $this->assertTrue($rows[$absent->id]['is_unavailable']);
        $this->assertSame(2, $rows[$absent->id]['tier']);

        $checkedIn = collect($this->getJson('/api/drivers?attendance=checked_in')->assertOk()->json('data'))
            ->pluck('id')->all();
        sort($checkedIn);
        $expected = [$far->id, $near->id];
        sort($expected);
        $this->assertSame($expected, $checkedIn);
    }

    public function test_today_summary_groups(): void
    {
        $this->travelTo(Carbon::parse('2026-11-18 12:00:00', 'Africa/Cairo'));
        $open = $this->createUserWithRole(UserRole::Driver);
        $closed = $this->createUserWithRole(UserRole::Driver);
        $this->createUserWithRole(UserRole::Driver);

        AttendanceLog::query()->create([
            'driver_id' => $open->id,
            'work_date' => '2026-11-18',
            'checked_in_at' => now(),
            'source' => 'scan',
        ]);
        AttendanceLog::query()->create([
            'driver_id' => $closed->id,
            'work_date' => '2026-11-18',
            'checked_in_at' => now()->subHours(8),
            'checked_out_at' => now(),
            'source' => 'scan',
        ]);

        $summary = $this->actingAsRole(UserRole::DriversAdmin)
            ->getJson('/api/attendance/today/summary')
            ->assertOk()
            ->json('data');

        $this->assertFalse($summary['off_day']);
        $this->assertSame(2, $summary['counts']['present']);
        $this->assertSame(1, $summary['counts']['checked_in']);
        $this->assertSame(1, $summary['counts']['checked_out']);
        $this->assertSame(1, $summary['counts']['absent']);
    }

    public function test_old_qr_version_is_rejected(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        $current = app(AttendanceQr::class)->payload();
        config(['attendance.qr_version' => 2]);

        Sanctum::actingAs($driver);
        $this->postJson('/api/attendance/check-in', $this->body(qr: $current))
            ->assertStatus(422)
            ->assertJsonPath('code', 'invalid_qr');
    }

    /**
     * @return array<string, mixed>
     */
    private function body(
        ?string $qr = null,
        ?float $lat = null,
        float $accuracy = 10,
        bool $mocked = false,
    ): array {
        return [
            'qr_payload' => $qr ?? app(AttendanceQr::class)->payload(),
            'lat' => $lat ?? self::HQ_LAT,
            'lng' => self::HQ_LNG,
            'accuracy_m' => $accuracy,
            'is_mocked' => $mocked,
        ];
    }

    private function north(float $meters): float
    {
        return self::HQ_LAT + rad2deg($meters / 6371000);
    }
}
