<?php

declare(strict_types=1);

namespace Tests\Feature\TripRequests;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\TripRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class AdminRequesterConfirmationTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    #[DataProvider('requesterRoles')]
    public function test_requester_can_confirm_their_own_finished_trip(UserRole $role): void
    {
        $requester = $this->createUserWithRole($role);
        $request = $this->linkedRequest($requester);

        Sanctum::actingAs($requester);
        $this->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
            'driver_showed_up' => true,
            'note' => 'on time',
        ])->assertOk()
            ->assertJsonPath('trip.status', 'completed')
            ->assertJsonPath('trip.confirmation_status', 'confirmed')
            ->assertJsonPath('trip.driver_showed_up', true);

        $trip = Trip::query()->findOrFail($request->trip_id);
        $this->assertSame(TripConfirmationStatus::Confirmed, $trip->confirmation_status);
        $this->assertSame($requester->id, $trip->confirmed_by);
        $this->assertSame('on time', $trip->confirmation_note);
    }

    public function test_non_requester_is_forbidden_including_admins(): void
    {
        $owner = $this->createUserWithRole(UserRole::Employee);
        $request = $this->linkedRequest($owner);

        foreach ([
            UserRole::Employee,
            UserRole::Driver,
            UserRole::DriversAdmin,
            UserRole::CompanyAdmin,
            UserRole::Admin,
        ] as $role) {
            $this->actingAsRole($role)
                ->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
                    'driver_showed_up' => false,
                ])
                ->assertForbidden();
        }

        $this->assertSame(
            TripConfirmationStatus::Pending,
            Trip::query()->findOrFail($request->trip_id)->confirmation_status,
        );
    }

    public function test_platform_admin_cannot_confirm_even_their_own_request(): void
    {
        $admin = $this->createUserWithRole(UserRole::Admin);
        $request = $this->linkedRequest($admin);

        Sanctum::actingAs($admin);
        $this->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
            'driver_showed_up' => true,
        ])->assertForbidden();

        $this->assertSame(
            TripConfirmationStatus::Pending,
            Trip::query()->findOrFail($request->trip_id)->confirmation_status,
        );
    }

    public function test_second_confirm_is_rejected(): void
    {
        $requester = $this->createUserWithRole(UserRole::DriversAdmin);
        $request = $this->linkedRequest($requester);
        Sanctum::actingAs($requester);

        $this->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
            'driver_showed_up' => false,
            'note' => 'kept',
        ])->assertOk();

        $this->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
            'driver_showed_up' => true,
            'note' => 'overwrite',
        ])->assertStatus(409)
            ->assertJsonPath('message', 'This trip has already been confirmed.');

        $trip = Trip::query()->findOrFail($request->trip_id);
        $this->assertFalse($trip->driver_showed_up);
        $this->assertSame('kept', $trip->confirmation_note);
        $this->assertSame($requester->id, $trip->confirmed_by);
    }

    public function test_auto_confirm_includes_admin_requested_trips(): void
    {
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);

        try {
            Carbon::setTestNow(Carbon::parse('2026-11-05 12:00:00', 'UTC'));

            $companyTrip = $this->linkedRequest(
                $companyAdmin,
                '2026-11-04 12:00:00',
            )->trip;
            $driversTrip = $this->linkedRequest(
                $driversAdmin,
                '2026-11-04 11:00:00',
            )->trip;
            $recent = $this->linkedRequest(
                $companyAdmin,
                '2026-11-04 12:00:01',
            )->trip;

            $this->artisan('trips:auto-confirm')
                ->expectsOutput('Marked 2 trip(s) as unconfirmed.')
                ->assertSuccessful();

            $this->assertSame(TripConfirmationStatus::Unconfirmed, $companyTrip->fresh()->confirmation_status);
            $this->assertSame(TripConfirmationStatus::Unconfirmed, $driversTrip->fresh()->confirmation_status);
            $this->assertNull($companyTrip->fresh()->confirmed_at);
            $this->assertNull($companyTrip->fresh()->driver_showed_up);
            $this->assertSame(TripConfirmationStatus::Pending, $recent->fresh()->confirmation_status);
        } finally {
            Carbon::setTestNow();
        }
    }

    public function test_my_trips_exposes_pending_confirmation_for_admin_requesters(): void
    {
        foreach ([UserRole::CompanyAdmin, UserRole::DriversAdmin] as $role) {
            $requester = $this->createUserWithRole($role);
            $request = $this->linkedRequest($requester);
            Sanctum::actingAs($requester);

            $row = collect($this->getJson('/api/my-trips?per_page=100')->assertOk()->json('data'))
                ->firstWhere('id', $request->trip_id);

            $this->assertIsArray($row);
            $this->assertSame('completed', $row['status']);
            $this->assertSame('pending', $row['confirmation_status']);
            $this->assertNull($row['driver_showed_up']);
        }
    }

    public function test_drivers_admin_requested_trip_is_on_my_trips_not_trips(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $request = $this->linkedRequest($admin);
        $tripId = (string) $request->trip_id;

        Sanctum::actingAs($admin);
        $this->assertContains($tripId, $this->ids('/api/my-trips?per_page=100'));
        $this->assertNotContains($tripId, $this->ids('/api/trips?per_page=100'));
        $this->assertNotContains($tripId, $this->ids('/api/trips?stage=awaiting_report&per_page=100'));
    }

    /**
     * @return list<array{UserRole}>
     */
    public static function requesterRoles(): array
    {
        return [
            [UserRole::Employee],
            [UserRole::CompanyAdmin],
            [UserRole::DriversAdmin],
        ];
    }

    private function linkedRequest(User $requester, ?string $requestedAt = null): TripRequest
    {
        $trip = Trip::factory()->create([
            'created_by' => $requester->id,
            'status' => TripStatus::Completed,
            'confirmation_status' => TripConfirmationStatus::Pending,
            'confirmation_requested_at' => $requestedAt ?? now(),
        ]);

        return TripRequest::factory()->approved()->create([
            'employee_id' => $requester->id,
            'requester_role' => $requester->role,
            'trip_id' => $trip->id,
        ]);
    }

    /**
     * @return list<string>
     */
    private function ids(string $url): array
    {
        return collect($this->getJson($url)->assertOk()->json('data'))->pluck('id')->all();
    }
}
