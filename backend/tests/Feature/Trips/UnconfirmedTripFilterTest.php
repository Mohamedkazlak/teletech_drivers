<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\TripRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class UnconfirmedTripFilterTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_unconfirmed_follows_trip_list_roles(): void
    {
        $trips = '/api/trips?unconfirmed=true';
        $mine = '/api/my-trips?unconfirmed=0';

        $this->getJson($trips)->assertUnauthorized();
        $this->getJson($mine)->assertUnauthorized();

        foreach ([UserRole::Admin, UserRole::CompanyAdmin, UserRole::DriversAdmin] as $role) {
            $this->actingAsRole($role)->getJson($trips)->assertOk();
        }

        foreach ([UserRole::Driver, UserRole::Employee] as $role) {
            $this->actingAsRole($role)->getJson($trips)->assertForbidden();
        }

        foreach (UserRole::cases() as $role) {
            $this->actingAsRole($role)->getJson($mine)->assertOk();
        }
    }

    public function test_unconfirmed_true_and_false_match_the_dashboard_definition(): void
    {
        $admin = $this->createUserWithRole(UserRole::Admin);
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);

        $inWeek = $this->trip($creator, $driver, '2026-11-10 12:00:00', TripConfirmationStatus::Unconfirmed);
        $older = $this->trip($creator, $driver, '2026-01-02 12:00:00', TripConfirmationStatus::Unconfirmed);
        $foreign = $this->trip($creator, $other, '2026-11-10 13:00:00', TripConfirmationStatus::Unconfirmed);
        $confirmed = $this->trip($creator, $driver, '2026-11-10 14:00:00', TripConfirmationStatus::Confirmed);
        $pending = $this->trip($creator, $driver, '2026-11-10 15:00:00', TripConfirmationStatus::Pending);
        $legacy = $this->trip($creator, $driver, '2026-11-10 16:00:00', null);
        $open = Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => $driver->id,
            'status' => TripStatus::Assigned,
            'scheduled_at' => '2026-11-10 09:00:00',
            'finished_at' => null,
            'confirmation_status' => null,
        ])->id;

        $unconfirmed = [$inWeek, $older, $foreign];
        $others = [$confirmed, $pending, $legacy, $open];
        foreach ([...$unconfirmed, ...$others] as $tripId) {
            $this->requestedBy($creator, $tripId);
        }

        Sanctum::actingAs($admin);

        $this->assertEqualsCanonicalizing($unconfirmed, $this->ids('/api/trips?unconfirmed=true'));
        $this->assertEqualsCanonicalizing($unconfirmed, $this->ids('/api/trips?unconfirmed=1'));
        $this->assertEqualsCanonicalizing($others, $this->ids('/api/trips?unconfirmed=false'));
        $this->assertEqualsCanonicalizing($others, $this->ids('/api/trips?unconfirmed=0'));

        $dashboard = $this->getJson('/api/admin/dashboard')->assertOk()->json('data.unconfirmed_trips');
        $listed = $this->getJson('/api/trips?unconfirmed=true&per_page=100')->assertOk();
        $excluded = $this->getJson('/api/trips?unconfirmed=false&per_page=100')->assertOk();
        $this->assertSame($dashboard, $listed->json('meta.total'));
        $this->assertSame(count($unconfirmed), $listed->json('meta.total'));
        $this->assertSame(count($others), $excluded->json('meta.total'));

        $this->assertEqualsCanonicalizing(
            [$inWeek, $foreign],
            $this->ids('/api/trips?unconfirmed=true&finished_period=week&date=2026-11-10'),
        );

        $this->getJson('/api/trips?unconfirmed=yes')->assertJsonValidationErrors(['unconfirmed']);

        Sanctum::actingAs($creator);
        $this->assertEqualsCanonicalizing($unconfirmed, $this->ids('/api/my-trips?unconfirmed=true'));
        $this->assertEqualsCanonicalizing($others, $this->ids('/api/my-trips?unconfirmed=false'));
        $this->getJson('/api/my-trips?unconfirmed=yes')->assertJsonValidationErrors(['unconfirmed']);

        Sanctum::actingAs($driver);
        $own = $this->ids('/api/my-trips?unconfirmed=true');
        $this->assertEqualsCanonicalizing([$inWeek, $older], $own);
        $this->assertNotContains($foreign, $own);
        $this->assertEqualsCanonicalizing($others, $this->ids('/api/my-trips?unconfirmed=false'));
    }

    private function trip(
        User $creator,
        User $driver,
        string $cairoLocal,
        ?TripConfirmationStatus $confirmation,
    ): string {
        return Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => $driver->id,
            'status' => TripStatus::Completed,
            'scheduled_at' => '2026-11-01 00:00:00',
            'finished_at' => Carbon::parse($cairoLocal, 'Africa/Cairo')->utc()->format('Y-m-d H:i:s'),
            'confirmation_status' => $confirmation,
        ])->id;
    }

    private function requestedBy(User $requester, string $tripId): void
    {
        TripRequest::factory()->approved()->create([
            'employee_id' => $requester->id,
            'requester_role' => $requester->role,
            'trip_id' => $tripId,
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
