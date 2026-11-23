<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\Branch;
use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Services\FleetPeriodRange;
use App\Models\Trip;
use App\Models\TripRequest;
use App\Models\User;
use DateTimeImmutable;
use DateTimeZone;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripListFiltersTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_branch_filter_matches_a_trip_with_at_least_one_passenger_in_that_branch(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $hq = $this->employeeIn(Branch::CompanyHeadquarters);
        $newHq = $this->employeeIn(Branch::NewHeadquarters);
        $blank = $this->employeeIn(null);

        $onlyHq = $this->tripWithPassengers($creator, [$hq]);
        $onlyNew = $this->tripWithPassengers($creator, [$newHq]);
        $both = $this->tripWithPassengers($creator, [$hq, $newHq, $blank]);
        $none = $this->createUnassignedTrip($creator)->id;

        $this->actingAsRole(UserRole::CompanyAdmin);

        $all = $this->ids('/api/trips');
        $this->assertEqualsCanonicalizing(
            [$onlyHq, $onlyNew, $both, $none],
            $all,
        );

        $this->assertEqualsCanonicalizing(
            [$onlyHq, $both],
            $this->ids('/api/trips?branch=company_headquarters'),
        );
        $this->assertEqualsCanonicalizing(
            [$onlyNew, $both],
            $this->ids('/api/trips?branch=new_headquarters'),
        );

        $mixed = collect($this->getJson('/api/trips')->json('data'))->firstWhere('id', $both);
        $this->assertSame(
            [Branch::CompanyHeadquarters->value, Branch::NewHeadquarters->value],
            $mixed['passengers_branches'],
        );

        $hqRow = collect($this->getJson('/api/trips')->json('data'))->firstWhere('id', $onlyHq);
        $this->assertSame([Branch::CompanyHeadquarters->value], $hqRow['passengers_branches']);
        $empty = collect($this->getJson('/api/trips')->json('data'))->firstWhere('id', $none);
        $this->assertSame([], $empty['passengers_branches']);

        $this->getJson('/api/trips?branch=headquarters')->assertJsonValidationErrors(['branch']);
    }

    public function test_stage_filter_groups_in_progress_and_keeps_status(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $ids = [];
        foreach (TripStatus::cases() as $status) {
            $ids[$status->value] = Trip::factory()->create([
                'created_by' => $creator->id,
                'status' => $status,
                'driver_id' => null,
                'scheduled_at' => now()->addHours($status === TripStatus::Unassigned ? 1 : 2),
                'confirmation_status' => $status === TripStatus::Completed
                    ? TripConfirmationStatus::Unconfirmed
                    : null,
            ])->id;
        }

        $this->actingAsRole(UserRole::DriversAdmin);

        $this->assertEqualsCanonicalizing(
            [$ids['going'], $ids['at_destination'], $ids['returning']],
            $this->ids('/api/trips?stage=in_progress'),
        );
        $this->assertSame([$ids['going']], $this->ids('/api/trips?status=going'));
        $this->assertSame([$ids['going']], $this->ids('/api/trips?stage=in_progress&status=going'));
        $this->assertSame([], $this->ids('/api/trips?stage=in_progress&status=completed'));
        $this->assertSame([$ids['completed']], $this->ids('/api/trips?stage=completed'));
        $this->assertSame([$ids['cancelled']], $this->ids('/api/trips?stage=cancelled'));
        $this->assertCount(7, $this->ids('/api/trips'));

        $awaitingReport = Trip::factory()->create([
            'created_by' => $creator->id,
            'status' => TripStatus::Completed,
            'confirmation_status' => TripConfirmationStatus::Pending,
            'scheduled_at' => now()->addHours(3),
        ])->id;

        $this->assertEqualsCanonicalizing(
            [$ids['unassigned'], $ids['assigned']],
            $this->ids('/api/trips?lifecycle=upcoming'),
        );
        $this->assertEqualsCanonicalizing(
            [$ids['going'], $ids['at_destination'], $ids['returning']],
            $this->ids('/api/trips?lifecycle=in_progress'),
        );
        $this->assertEqualsCanonicalizing(
            [$ids['completed'], $awaitingReport],
            $this->ids('/api/trips?lifecycle=completed'),
        );
        $this->assertSame([$ids['cancelled']], $this->ids('/api/trips?lifecycle=cancelled'));
        $this->getJson('/api/trips?lifecycle=pending')->assertJsonValidationErrors(['lifecycle']);

        $this->getJson('/api/trips?stage=needs_driver')->assertJsonValidationErrors(['stage']);
        $this->getJson('/api/trips?status=all_assigned')->assertJsonValidationErrors(['status']);
    }

    public function test_created_by_me_buckets_are_paginated_and_drivers_admin_only(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $other = $this->createUserWithRole(UserRole::DriversAdmin);

        $active = [];
        foreach ([
            TripStatus::Unassigned,
            TripStatus::Assigned,
            TripStatus::Going,
            TripStatus::AtDestination,
            TripStatus::Returning,
        ] as $status) {
            $active[] = Trip::factory()->create([
                'created_by' => $admin->id,
                'status' => $status,
            ])->id;
        }
        $completed = Trip::factory()->create([
            'created_by' => $admin->id,
            'status' => TripStatus::Completed,
        ])->id;
        $cancelled = Trip::factory()->create([
            'created_by' => $admin->id,
            'status' => TripStatus::Cancelled,
        ])->id;
        $foreign = Trip::factory()->create([
            'created_by' => $other->id,
            'status' => TripStatus::Unassigned,
        ])->id;

        foreach ([UserRole::CompanyAdmin, UserRole::Admin, UserRole::Driver, UserRole::Employee] as $role) {
            $this->actingAsRole($role)->getJson('/api/trips/created-by-me')->assertForbidden();
        }

        Sanctum::actingAs($admin);
        $this->assertEqualsCanonicalizing($active, $this->ids('/api/trips/created-by-me?bucket=active'));
        $this->assertSame([$completed], $this->ids('/api/trips/created-by-me?bucket=completed'));
        $this->assertSame([$cancelled], $this->ids('/api/trips/created-by-me?bucket=cancelled'));

        $all = $this->ids('/api/trips/created-by-me');
        $this->assertCount(7, $all);
        $this->assertNotContains($foreign, $all);

        $page = $this->getJson('/api/trips/created-by-me?bucket=active&per_page=1&page=1')
            ->assertOk()
            ->assertJsonPath('meta.total', 5)
            ->assertJsonPath('meta.per_page', 1)
            ->assertJsonPath('meta.current_page', 1)
            ->assertJsonPath('meta.last_page', 5)
            ->assertJsonCount(1, 'data');
        $this->assertContains($page->json('data.0.id'), $active);

        $this->getJson('/api/trips/created-by-me?bucket=open')->assertJsonValidationErrors(['bucket']);
    }

    public function test_driver_mine_applies_cairo_period_to_scheduled_at_and_all_assigned(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $range = (new FleetPeriodRange(new DateTimeZone('Africa/Cairo'), 'Saturday'))
            ->containing('week', '2026-11-04');

        $atStart = $this->driverTrip($admin, $driver, TripStatus::Assigned, $range['start']);
        $inside = $this->driverTrip(
            $admin,
            $driver,
            TripStatus::Going,
            new DateTimeImmutable('2026-11-04 12:00:00', new DateTimeZone('Africa/Cairo')),
        );
        $before = $this->driverTrip($admin, $driver, TripStatus::Assigned, $range['start']->modify('-1 second'));
        $atEnd = $this->driverTrip($admin, $driver, TripStatus::Assigned, $range['end_exclusive']);
        $completed = $this->driverTrip($admin, $driver, TripStatus::Completed, $range['start']->modify('+2 hours'));
        $unassigned = $this->driverTrip($admin, $driver, TripStatus::Unassigned, $range['start']->modify('+3 hours'));
        $atDestination = $this->driverTrip($admin, $driver, TripStatus::AtDestination, $range['start']->modify('+4 hours'));
        $returning = $this->driverTrip($admin, $driver, TripStatus::Returning, $range['start']->modify('+5 hours'));
        $cancelled = $this->driverTrip($admin, $driver, TripStatus::Cancelled, $range['start']->modify('+6 hours'));

        Sanctum::actingAs($driver);

        DB::flushQueryLog();
        DB::enableQueryLog();
        $week = $this->ids('/api/trips/mine?period=week&date=2026-11-04');
        $sql = strtolower(collect(DB::getQueryLog())->pluck('query')->implode("\n"));
        $this->assertStringContainsString('>=', $sql);
        $this->assertStringNotContainsString('date_trunc', $sql);
        $this->assertStringNotContainsString('extract(', $sql);
        $this->assertStringNotContainsString('weekday', $sql);

        $this->assertEqualsCanonicalizing(
            [$atStart, $inside, $completed, $unassigned, $atDestination, $returning, $cancelled],
            $week,
        );
        $this->assertNotContains($before, $week);
        $this->assertNotContains($atEnd, $week);

        $this->assertEqualsCanonicalizing(
            [$atStart, $inside, $atDestination, $returning],
            $this->ids('/api/trips/mine?period=week&date=2026-11-04&status=all_assigned'),
        );
        $this->assertSame(
            [$atStart],
            $this->ids('/api/trips/mine?period=week&date=2026-11-04&status=assigned'),
        );
        $this->assertContains($before, $this->ids('/api/trips/mine?status=assigned'));
        $this->assertContains($before, $this->ids('/api/trips/mine?date=2026-11-04'));

        $this->getJson('/api/trips/mine?period=day')->assertJsonValidationErrors(['period']);

        Config::set('fleet.week_starts_on', 'Monday');
        $mondayWeek = $this->ids('/api/trips/mine?period=week&date=2026-11-04');
        $this->assertNotContains($atStart, $mondayWeek);
        $this->assertContains($inside, $mondayWeek);
    }

    public function test_driver_mine_period_defaults_the_date_to_today_in_cairo(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $inside = $this->driverTrip(
            $admin,
            $driver,
            TripStatus::Assigned,
            new DateTimeImmutable('2026-11-04 12:00:00', new DateTimeZone('Africa/Cairo')),
        );
        $outside = $this->driverTrip(
            $admin,
            $driver,
            TripStatus::Assigned,
            new DateTimeImmutable('2026-01-15 12:00:00', new DateTimeZone('Africa/Cairo')),
        );

        Sanctum::actingAs($driver);
        try {
            Carbon::setTestNow('2026-11-04 10:00:00');
            $ids = $this->ids('/api/trips/mine?period=week');
        } finally {
            Carbon::setTestNow();
        }

        $this->assertSame([$inside], $ids);
        $this->assertNotContains($outside, $ids);
    }

    private function employeeIn(?Branch $branch): User
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $employee->branch = $branch;
        $employee->save();

        return $employee;
    }

    /**
     * @param  list<User>  $passengers
     */
    private function tripWithPassengers(User $creator, array $passengers): string
    {
        $trip = $this->createUnassignedTrip($creator);
        foreach ($passengers as $passenger) {
            TripRequest::factory()->approved()->create([
                'employee_id' => $passenger->id,
                'trip_id' => $trip->id,
                'requester_role' => UserRole::Employee,
            ]);
        }

        return $trip->id;
    }

    private function driverTrip(
        User $creator,
        User $driver,
        TripStatus $status,
        DateTimeImmutable $scheduledAt,
    ): string {
        return Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => $driver->id,
            'status' => $status,
            'scheduled_at' => $scheduledAt->setTimezone(new DateTimeZone('UTC'))->format('Y-m-d H:i:s'),
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
