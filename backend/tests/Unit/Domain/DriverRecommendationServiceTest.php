<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Entities\Driver;
use App\Domain\Entities\Trip;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Services\DriverRecommendationService;
use App\Domain\Services\DriverScheduleConflict;
use App\Domain\Services\FleetPeriodRange;
use DateTimeImmutable;
use DateTimeZone;
use PHPUnit\Framework\TestCase;

final class DriverRecommendationServiceTest extends TestCase
{
    private DriverRecommendationService $service;

    private DateTimeZone $tz;

    protected function setUp(): void
    {
        parent::setUp();
        $this->tz = new DateTimeZone('Africa/Cairo');
        $this->service = new DriverRecommendationService(
            scheduleConflict: new DriverScheduleConflict(2),
            periods: new FleetPeriodRange($this->tz, 'Saturday'),
        );
    }

    public function test_tiers_favorite_available_and_rest(): void
    {
        $trip = $this->trip('trip', null, new DateTimeImmutable('2026-11-04T10:00:00+00:00'));
        $fav = $this->driver('a', 'Alice', AvailabilityStatus::Available, ['place-1']);
        $avail = $this->driver('b', 'Bob', AvailabilityStatus::Available, []);
        $unavail = $this->driver('c', 'Carol', AvailabilityStatus::Unavailable, ['place-1']);

        $ranked = $this->service->recommend(
            trip: $trip,
            drivers: [$unavail, $avail, $fav],
            allTrips: [$trip],
            tripPlaceIds: ['place-1'],
            now: new DateTimeImmutable('2026-11-04T12:00:00+00:00'),
            timezone: $this->tz,
        );

        $this->assertSame(['a', 'b', 'c'], array_map(static fn ($r) => $r->driver->user->id, $ranked));
        $this->assertSame(0, $ranked[0]->tier);
        $this->assertTrue($ranked[0]->hasFavoriteMatch);
        $this->assertSame(1, $ranked[1]->tier);
        $this->assertSame(2, $ranked[2]->tier);
        $this->assertTrue($ranked[2]->isUnavailable);
        $this->assertTrue($ranked[2]->needsConfirmation);
    }

    public function test_tie_break_fewer_trips_then_name(): void
    {
        $scheduled = new DateTimeImmutable('2026-11-04T10:00:00+00:00'); // Wed
        $trip = $this->trip('target', null, $scheduled);
        $zoe = $this->driver('z', 'Zoe', AvailabilityStatus::Available, []);
        $amy = $this->driver('a', 'Amy', AvailabilityStatus::Available, []);

        $weekTrip = $this->trip('w1', 'z', $scheduled->modify('+1 day'), TripStatus::Assigned);

        $ranked = $this->service->recommend(
            trip: $trip,
            drivers: [$zoe, $amy],
            allTrips: [$trip, $weekTrip],
            tripPlaceIds: [],
            now: $scheduled,
            timezone: $this->tz,
        );

        $this->assertSame('a', $ranked[0]->driver->user->id);
        $this->assertSame(0, $ranked[0]->tripsThisWeek);
        $this->assertSame(1, $ranked[1]->tripsThisWeek);
    }

    public function test_trips_this_week_uses_the_saturday_fleet_week(): void
    {
        $now = new DateTimeImmutable('2026-11-04T10:00:00+02:00');
        $target = $this->trip('target', null, $now);
        $saturdayDriver = $this->driver('sat', 'Sam', AvailabilityStatus::Available, []);
        $sundayDriver = $this->driver('sun', 'Sue', AvailabilityStatus::Available, []);
        $inside = $this->trip(
            'inside',
            'sat',
            new DateTimeImmutable('2026-10-31T10:00:00+02:00'),
            TripStatus::Assigned,
        );
        $outside = $this->trip(
            'outside',
            'sun',
            new DateTimeImmutable('2026-11-08T10:00:00+02:00'),
            TripStatus::Assigned,
        );

        $ranked = $this->service->recommend(
            trip: $target,
            drivers: [$sundayDriver, $saturdayDriver],
            allTrips: [$target, $inside, $outside],
            tripPlaceIds: [],
            now: $now,
            timezone: $this->tz,
        );

        $byId = [];
        foreach ($ranked as $row) {
            $byId[$row->driver->user->id] = $row->tripsThisWeek;
        }

        $this->assertSame(1, $byId['sat']);
        $this->assertSame(0, $byId['sun']);
    }

    public function test_conflict_window_exactly_two_hours_inclusive(): void
    {
        $scheduled = new DateTimeImmutable('2026-11-04T10:00:00+00:00');
        $trip = $this->trip('target', null, $scheduled);
        $driver = $this->driver('d1', 'Dan', AvailabilityStatus::Available, []);
        $other = $this->trip(
            'other',
            'd1',
            $scheduled->modify('+2 hours'),
            TripStatus::Assigned,
        );

        $ranked = $this->service->recommend(
            trip: $trip,
            drivers: [$driver],
            allTrips: [$trip, $other],
            tripPlaceIds: [],
            now: $scheduled,
            timezone: $this->tz,
        );

        $this->assertFalse($ranked[0]->isOnActiveTrip);
        $this->assertTrue($ranked[0]->hasConflict);
        $this->assertTrue($ranked[0]->needsConfirmation);
        $this->assertSame(2, $ranked[0]->tier);
    }

    public function test_active_trip_sets_conflict_but_not_tier_alone(): void
    {
        $scheduled = new DateTimeImmutable('2026-11-04T10:00:00+00:00');
        $trip = $this->trip('target', null, $scheduled);
        $driver = $this->driver('d1', 'Dan', AvailabilityStatus::Available, []);
        // Far from schedule window but in progress
        $active = $this->trip(
            'active',
            'd1',
            $scheduled->modify('+1 day'),
            TripStatus::Going,
        );

        $ranked = $this->service->recommend(
            trip: $trip,
            drivers: [$driver],
            allTrips: [$trip, $active],
            tripPlaceIds: [],
            now: $scheduled,
            timezone: $this->tz,
        );

        // An active trip clears derived availability, so the driver leaves tier 1.
        $this->assertSame(2, $ranked[0]->tier);
        $this->assertTrue($ranked[0]->isUnavailable);
        $this->assertTrue($ranked[0]->isOnActiveTrip);
        $this->assertTrue($ranked[0]->hasConflict);
        $this->assertTrue($ranked[0]->needsConfirmation);
    }

    public function test_is_on_active_trip_is_only_going_at_destination_or_returning(): void
    {
        $scheduled = new DateTimeImmutable('2026-11-04T10:00:00+00:00');
        $trip = $this->trip('target', null, $scheduled);
        $driver = $this->driver('d1', 'Dan', AvailabilityStatus::Available, []);

        $cases = [
            [TripStatus::Going, true],
            [TripStatus::AtDestination, true],
            [TripStatus::Returning, true],
            [TripStatus::Assigned, false],
            [TripStatus::Completed, false],
            [TripStatus::Cancelled, false],
        ];

        foreach ($cases as [$status, $onActiveTrip]) {
            $other = $this->trip('other', 'd1', $scheduled->modify('+3 days'), $status);
            $ranked = $this->service->recommend(
                trip: $trip,
                drivers: [$driver],
                allTrips: [$trip, $other],
                tripPlaceIds: [],
                now: $scheduled,
                timezone: $this->tz,
            );

            $this->assertSame($onActiveTrip, $ranked[0]->isOnActiveTrip, $status->value);
            $this->assertSame($onActiveTrip, $ranked[0]->hasConflict, $status->value);
            $this->assertSame($onActiveTrip, $ranked[0]->needsConfirmation, $status->value);
            $this->assertSame($onActiveTrip ? 2 : 1, $ranked[0]->tier, $status->value);
            $this->assertSame($onActiveTrip, $ranked[0]->isUnavailable, $status->value);
        }
    }

    public function test_favorite_via_pickup_and_destination(): void
    {
        $trip = $this->trip('t', null, new DateTimeImmutable('2026-11-04T10:00:00+00:00'));
        $viaPickup = $this->driver('p', 'Pat', AvailabilityStatus::Available, ['pickup-1']);
        $viaDest = $this->driver('d', 'Dot', AvailabilityStatus::Available, ['dest-1']);

        $ranked = $this->service->recommend(
            trip: $trip,
            drivers: [$viaPickup, $viaDest],
            allTrips: [$trip],
            tripPlaceIds: ['pickup-1', 'dest-1'],
            now: new DateTimeImmutable('2026-11-04T10:00:00+00:00'),
            timezone: $this->tz,
        );

        $this->assertTrue($ranked[0]->hasFavoriteMatch);
        $this->assertTrue($ranked[1]->hasFavoriteMatch);
        $this->assertSame(0, $ranked[0]->tier);
        $this->assertSame(0, $ranked[1]->tier);
    }

    public function test_excludes_self_conflict_on_same_trip_id(): void
    {
        $scheduled = new DateTimeImmutable('2026-11-04T10:00:00+00:00');
        $trip = $this->trip('target', 'd1', $scheduled, TripStatus::Assigned);
        $driver = $this->driver('d1', 'Dan', AvailabilityStatus::Available, []);

        $ranked = $this->service->recommend(
            trip: $trip,
            drivers: [$driver],
            allTrips: [$trip],
            tripPlaceIds: [],
            now: $scheduled,
            timezone: $this->tz,
        );

        $this->assertFalse($ranked[0]->hasConflict);
        $this->assertSame(1, $ranked[0]->tier);
    }

    /**
     * @param  list<string>  $favorites
     */
    private function driver(
        string $id,
        string $name,
        AvailabilityStatus $availability,
        array $favorites,
    ): Driver {
        return new Driver(
            user: new User(
                id: $id,
                nameEn: $name,
                nameAr: null,
                email: $id.'@example.com',
                passwordHash: 'x',
                role: UserRole::Driver,
                isActive: true,
                phone: null,
                branch: null,
                availabilityStatus: $availability,
            ),
            nationalId: 'n',
            carLicense: 'c',
            personalLicense: 'p',
            favoritePlaceIds: $favorites,
        );
    }

    private function trip(
        string $id,
        ?string $driverId,
        DateTimeImmutable $scheduledAt,
        TripStatus $status = TripStatus::Unassigned,
    ): Trip {
        return new Trip(
            id: $id,
            driverId: $driverId,
            scheduledAt: $scheduledAt,
            status: $status,
            createdBy: 'admin',
            pickupSummary: 'P',
            destinationSummary: 'D',
            goingStartedAt: null,
            goingEndedAt: null,
            returnStartedAt: null,
            finishedAt: null,
            startLat: null,
            startLng: null,
            goingDistanceM: null,
            returnDistanceM: null,
            totalDistanceM: null,
            goingRoute: null,
            returnRoute: null,
            createdAt: $scheduledAt,
        );
    }
}
