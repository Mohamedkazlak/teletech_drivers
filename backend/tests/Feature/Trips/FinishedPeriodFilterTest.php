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

final class FinishedPeriodFilterTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_finished_period_follows_trip_list_roles(): void
    {
        $trips = '/api/trips?finished_period=week&date=2026-11-10';
        $mine = '/api/my-trips?finished_period=day&date=2026-11-10';

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

    public function test_finished_period_uses_cairo_and_a_saturday_week_on_finished_at(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);

        $friday = $this->finished($creator, $driver, '2026-11-06 23:30:00');
        $saturdayStart = $this->finished($creator, $driver, '2026-11-07 00:00:00');
        $utcFridayThatIsCairoSaturday = $this->finishedUtc($creator, $driver, '2026-11-06 22:30:00');
        $inside = $this->finished($creator, $driver, '2026-11-10 12:00:00');
        $nextSaturday = $this->finished($creator, $driver, '2026-11-14 00:00:00');
        $october = $this->finished($creator, $driver, '2026-10-31 23:30:00');
        $novemberStart = $this->finished($creator, $driver, '2026-11-01 00:30:00');
        $decemberStart = $this->finished($creator, $driver, '2026-12-01 00:30:00');
        $otherInside = $this->finished($creator, $other, '2026-11-10 15:00:00');
        $unfinished = Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => $driver->id,
            'status' => TripStatus::Assigned,
            'scheduled_at' => '2026-11-10 08:00:00',
            'finished_at' => null,
        ])->id;

        $week = [$saturdayStart, $utcFridayThatIsCairoSaturday, $inside, $otherInside];
        foreach ([
            $friday,
            $saturdayStart,
            $utcFridayThatIsCairoSaturday,
            $inside,
            $nextSaturday,
            $october,
            $novemberStart,
            $decemberStart,
            $otherInside,
            $unfinished,
        ] as $tripId) {
            $this->requestedBy($creator, $tripId);
        }

        $fleet = $this->createUserWithRole(UserRole::CompanyAdmin);
        Sanctum::actingAs($fleet);

        $this->assertEqualsCanonicalizing($week, $this->ids('/api/trips?finished_period=week&date=2026-11-10'));
        $this->assertNotContains($friday, $this->ids('/api/trips?finished_period=week&date=2026-11-10'));
        $this->assertNotContains($nextSaturday, $this->ids('/api/trips?finished_period=week&date=2026-11-10'));
        $this->assertNotContains($unfinished, $this->ids('/api/trips?finished_period=week&date=2026-11-10'));

        $this->assertEqualsCanonicalizing(
            [$utcFridayThatIsCairoSaturday, $saturdayStart],
            $this->ids('/api/trips?finished_period=day&date=2026-11-07'),
        );

        $this->assertEqualsCanonicalizing(
            [$friday, $saturdayStart, $utcFridayThatIsCairoSaturday, $inside, $nextSaturday, $novemberStart, $otherInside],
            $this->ids('/api/trips?finished_period=month&date=2026-11-10'),
        );
        $this->assertNotContains($october, $this->ids('/api/trips?finished_period=month&date=2026-11-10'));
        $this->assertNotContains($decemberStart, $this->ids('/api/trips?finished_period=month&date=2026-11-10'));
        $this->assertNotContains($unfinished, $this->ids('/api/trips?finished_period=month&date=2026-11-10'));

        $custom = $this->ids('/api/trips?finished_period=custom');
        $this->assertContains($october, $custom);
        $this->assertContains($inside, $custom);
        $this->assertContains($unfinished, $custom);

        Sanctum::actingAs($creator);
        $this->assertEqualsCanonicalizing($week, $this->ids('/api/my-trips?finished_period=week&date=2026-11-10'));
        $this->assertSame([$friday], $this->ids('/api/my-trips?finished_period=day&date=2026-11-06'));
        $this->assertSame([], $this->ids('/api/trips?finished_period=week&date=2026-11-10'));

        Sanctum::actingAs($driver);
        $ownWeek = $this->ids('/api/my-trips?finished_period=week&date=2026-11-10');
        $this->assertContains($inside, $ownWeek);
        $this->assertNotContains($otherInside, $ownWeek);
        $this->assertNotContains($friday, $ownWeek);

        Sanctum::actingAs($creator);
        foreach (['year', 'all', 'fortnight'] as $period) {
            $this->getJson('/api/trips?finished_period='.$period)->assertJsonValidationErrors(['finished_period']);
            $this->getJson('/api/my-trips?finished_period='.$period)->assertJsonValidationErrors(['finished_period']);
        }
    }

    public function test_omitted_finished_period_date_uses_today_in_cairo(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $today = $this->finished($creator, $driver, '2026-11-10 12:00:00');
        $yesterday = $this->finished($creator, $driver, '2026-11-09 12:00:00');

        Sanctum::actingAs($creator);
        $this->travelTo(Carbon::parse('2026-11-10 10:00:00', 'UTC'));

        $this->assertSame([$today], $this->ids('/api/trips?finished_period=day'));
        $this->assertNotContains($yesterday, $this->ids('/api/my-trips?finished_period=day'));
    }

    public function test_finished_period_combines_with_the_other_list_filters(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);

        $match = $this->at(
            $creator,
            $driver,
            TripStatus::Completed,
            '2026-11-10 12:00:00',
            '2026-11-10 18:00:00',
            TripConfirmationStatus::Unconfirmed,
        );
        $scheduledEarlier = $this->at(
            $creator,
            $driver,
            TripStatus::Completed,
            '2026-11-08 12:00:00',
            '2026-11-10 18:00:00',
        );
        $finishedLater = $this->at(
            $creator,
            $driver,
            TripStatus::Completed,
            '2026-11-10 12:00:00',
            '2026-11-15 12:00:00',
        );
        $assigned = $this->at(
            $creator,
            $driver,
            TripStatus::Assigned,
            '2026-11-10 13:00:00',
            '2026-11-10 19:00:00',
        );
        $otherDriver = $this->at(
            $creator,
            $other,
            TripStatus::Completed,
            '2026-11-10 14:00:00',
            '2026-11-10 20:00:00',
        );

        $fleet = $this->createUserWithRole(UserRole::CompanyAdmin);
        Sanctum::actingAs($fleet);

        $this->assertEqualsCanonicalizing(
            [$match, $assigned, $otherDriver],
            $this->ids('/api/trips?period=day&finished_period=week&date=2026-11-10'),
        );
        $this->assertNotContains(
            $scheduledEarlier,
            $this->ids('/api/trips?period=day&finished_period=week&date=2026-11-10'),
        );
        $this->assertNotContains(
            $finishedLater,
            $this->ids('/api/trips?period=day&finished_period=week&date=2026-11-10'),
        );

        $this->assertEqualsCanonicalizing(
            [$match, $otherDriver],
            $this->ids('/api/trips?period=day&finished_period=week&date=2026-11-10&status=completed'),
        );
        $this->assertSame(
            [$match],
            $this->ids('/api/trips?finished_period=week&date=2026-11-10&status=completed&driver_id='.$driver->id.'&unconfirmed=true'),
        );

        $window = 'date_from=2026-11-10T00:00:00%2B02:00&date_to=2026-11-10T23:59:59%2B02:00';
        $this->assertEqualsCanonicalizing(
            [$match, $assigned, $otherDriver],
            $this->ids('/api/trips?finished_period=week&date=2026-11-10&'.$window),
        );
        $this->assertNotContains($finishedLater, $this->ids('/api/trips?finished_period=week&date=2026-11-10&'.$window));
        $this->assertNotContains($scheduledEarlier, $this->ids('/api/trips?finished_period=week&date=2026-11-10&'.$window));

        Sanctum::actingAs($driver);
        $this->assertEqualsCanonicalizing(
            [$match, $assigned],
            $this->ids('/api/my-trips?finished_period=week&date=2026-11-10&driver_id='.$driver->id.'&period=day'),
        );
    }

    private function finished(User $creator, User $driver, string $cairoLocal): string
    {
        return $this->finishedUtc(
            $creator,
            $driver,
            Carbon::parse($cairoLocal, 'Africa/Cairo')->utc()->format('Y-m-d H:i:s'),
        );
    }

    private function finishedUtc(User $creator, User $driver, string $utc): string
    {
        return Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => $driver->id,
            'status' => TripStatus::Completed,
            'scheduled_at' => Carbon::parse('2026-01-01 00:00:00', 'Africa/Cairo')->utc()->format('Y-m-d H:i:s'),
            'finished_at' => $utc,
        ])->id;
    }

    private function at(
        User $creator,
        User $driver,
        TripStatus $status,
        string $scheduledCairo,
        string $finishedCairo,
        ?TripConfirmationStatus $confirmation = null,
    ): string {
        return Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => $driver->id,
            'status' => $status,
            'scheduled_at' => Carbon::parse($scheduledCairo, 'Africa/Cairo')->utc()->format('Y-m-d H:i:s'),
            'finished_at' => Carbon::parse($finishedCairo, 'Africa/Cairo')->utc()->format('Y-m-d H:i:s'),
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
