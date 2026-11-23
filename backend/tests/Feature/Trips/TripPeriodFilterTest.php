<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripPeriodFilterTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_period_uses_cairo_and_a_saturday_week_until_dates_are_sent(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);

        $fridayCairo = $this->at($creator, '2026-11-06 23:30:00');
        $saturdayStart = $this->at($creator, '2026-11-07 00:00:00');
        $utcFridayThatIsCairoSaturday = $this->atUtc($creator, '2026-11-06 22:30:00');
        $inside = $this->at($creator, '2026-11-10 12:00:00');
        $nextSaturday = $this->at($creator, '2026-11-14 00:00:00');
        $october = $this->at($creator, '2026-10-31 23:30:00');
        $novemberStart = $this->at($creator, '2026-11-01 00:30:00');
        $decemberStart = $this->at($creator, '2026-12-01 00:30:00');

        $week = [
            $saturdayStart,
            $utcFridayThatIsCairoSaturday,
            $inside,
        ];

        foreach ([UserRole::Admin, UserRole::CompanyAdmin, UserRole::DriversAdmin] as $role) {
            $this->actingAsRole($role);

            $this->assertEqualsCanonicalizing($week, $this->ids('/api/trips?period=week&date=2026-11-10'));
            $this->assertNotContains($fridayCairo, $this->ids('/api/trips?period=week&date=2026-11-10'));
            $this->assertNotContains($nextSaturday, $this->ids('/api/trips?period=week&date=2026-11-10'));

            $this->assertEqualsCanonicalizing(
                [$utcFridayThatIsCairoSaturday, $saturdayStart],
                $this->ids('/api/trips?period=day&date=2026-11-07'),
            );
            $this->assertSame(
                [$fridayCairo],
                $this->ids('/api/trips?period=day&date=2026-11-06'),
            );

            $this->assertEqualsCanonicalizing(
                [
                    $fridayCairo,
                    $saturdayStart,
                    $utcFridayThatIsCairoSaturday,
                    $inside,
                    $nextSaturday,
                    $novemberStart,
                ],
                $this->ids('/api/trips?period=month&date=2026-11-10'),
            );
            $this->assertNotContains($october, $this->ids('/api/trips?period=month&date=2026-11-10'));
            $this->assertNotContains($decemberStart, $this->ids('/api/trips?period=month&date=2026-11-10'));
        }

        $this->actingAsRole(UserRole::Admin);
        $this->assertContains($october, $this->ids('/api/trips?period=custom'));
        $this->assertContains($inside, $this->ids('/api/trips?period=custom'));

        $this->assertSame(
            [$inside],
            $this->ids('/api/trips?period=day&date=2026-11-07&date_from=2026-11-10T00:00:00%2B02:00&date_to=2026-11-10T23:59:59%2B02:00'),
        );
        $this->assertSame(
            [$inside],
            $this->ids('/api/trips?date_from=2026-11-10T00:00:00%2B02:00&date_to=2026-11-10T23:59:59%2B02:00'),
        );
        $this->assertSame([], $this->ids('/api/trips?period=week&date=2026-11-10&status=completed'));

        foreach (['year', 'all', 'fortnight'] as $period) {
            $this->getJson('/api/trips?period='.$period)->assertJsonValidationErrors(['period']);
        }

        $this->actingAsRole(UserRole::Employee)->getJson('/api/trips?period=week')->assertForbidden();
        $this->actingAsRole(UserRole::Driver)->getJson('/api/trips?period=day')->assertForbidden();
    }

    public function test_omitted_period_date_uses_today_in_cairo(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $today = $this->at($creator, '2026-11-10 12:00:00');
        $yesterday = $this->at($creator, '2026-11-09 12:00:00');

        $this->actingAsRole(UserRole::CompanyAdmin);
        try {
            Carbon::setTestNow(Carbon::parse('2026-11-10 10:00:00', 'UTC'));
            $ids = $this->ids('/api/trips?period=day');
        } finally {
            Carbon::setTestNow();
        }

        $this->assertSame([$today], $ids);
        $this->assertNotContains($yesterday, $ids);
    }

    private function at(User $creator, string $cairoLocal): string
    {
        return $this->atUtc($creator, Carbon::parse($cairoLocal, 'Africa/Cairo')->utc()->format('Y-m-d H:i:s'));
    }

    private function atUtc(User $creator, string $utc): string
    {
        return Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => null,
            'status' => TripStatus::Assigned,
            'scheduled_at' => $utc,
        ])->id;
    }

    /**
     * @return list<string>
     */
    private function ids(string $url): array
    {
        return collect($this->getJson($url)->assertOk()->json('data'))->pluck('id')->all();
    }
}
