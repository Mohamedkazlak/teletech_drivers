<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Entities\Driver;
use App\Domain\Entities\DriverRecommendation;
use App\Domain\Entities\Trip;
use App\Domain\Enums\TripStatus;
use App\Domain\Specifications\AvailableDriverSpecification;
use App\Domain\Specifications\FavoritePlaceMatchSpecification;
use App\Domain\Specifications\InProgressTripSpecification;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Domain service: ranks drivers for assign / reassign (mirrors Flutter tiers).
 *
 * Tiers:
 * 0 = available + no schedule conflict + favorite match
 * 1 = available + no schedule conflict
 * 2 = everything else
 * Tie-break: fewer trips this week, then name_en (case-insensitive).
 * "This week" is the Saturday-start fleet week from FleetPeriodRange.
 *
 * A driver on an active trip is not available, so the tier drops with
 * availability. Distance from headquarters (today's check-in) breaks ties
 * after the weekly trip count. Closer drivers come first.
 */
final class DriverRecommendationService
{
    public function __construct(
        private readonly DriverScheduleConflict $scheduleConflict,
        private readonly FleetPeriodRange $periods,
        private readonly AvailableDriverSpecification $availableSpec = new AvailableDriverSpecification,
        private readonly FavoritePlaceMatchSpecification $favoriteSpec = new FavoritePlaceMatchSpecification,
        private readonly InProgressTripSpecification $inProgressSpec = new InProgressTripSpecification,
    ) {}

    /**
     * @param  list<Driver>  $drivers
     * @param  list<Trip>  $allTrips
     * @param  list<string>  $tripPlaceIds  pickup/destination place ids of linked requests
     * @return list<DriverRecommendation>
     */
    public function recommend(
        Trip $trip,
        array $drivers,
        array $allTrips,
        array $tripPlaceIds,
        DateTimeImmutable $now,
        DateTimeZone $timezone,
    ): array {
        $ranked = [];
        foreach ($drivers as $driver) {
            $ranked[] = $this->buildOne(
                driver: $driver,
                trip: $trip,
                allTrips: $allTrips,
                tripPlaceIds: $tripPlaceIds,
                now: $now,
                timezone: $timezone,
            );
        }

        usort($ranked, static function (DriverRecommendation $a, DriverRecommendation $b): int {
            $tierCompare = $a->tier <=> $b->tier;
            if ($tierCompare !== 0) {
                return $tierCompare;
            }

            $loadCompare = $a->tripsThisWeek <=> $b->tripsThisWeek;
            if ($loadCompare !== 0) {
                return $loadCompare;
            }

            $distanceCompare = self::compareHqDistance(
                $a->driver->checkInDistanceM,
                $b->driver->checkInDistanceM,
            );
            if ($distanceCompare !== 0) {
                return $distanceCompare;
            }

            return strcasecmp($a->driver->user->nameEn, $b->driver->user->nameEn);
        });

        return $ranked;
    }

    /**
     * @param  list<Trip>  $allTrips
     * @param  list<string>  $tripPlaceIds
     */
    private function buildOne(
        Driver $driver,
        Trip $trip,
        array $allTrips,
        array $tripPlaceIds,
        DateTimeImmutable $now,
        DateTimeZone $timezone,
    ): DriverRecommendation {
        $checkedIn = $this->availableSpec->isSatisfiedBy($driver);
        $isOnActiveTrip = $this->driverHasActiveTrip($driver->user->id, $allTrips);
        $isAvailable = $checkedIn && ! $isOnActiveTrip;
        $hasScheduleConflict = $this->scheduleConflict->hasConflict(
            trips: $allTrips,
            driverId: $driver->user->id,
            scheduledAt: $trip->scheduledAt,
            excludingTripId: $trip->id,
        );
        $favoriteMatch = $this->favoriteSpec->isSatisfiedBy(
            $driver->favoritePlaceIds,
            $tripPlaceIds,
        );
        $tripsThisWeek = $this->countTripsThisWeek(
            driverId: $driver->user->id,
            trips: $allTrips,
            now: $now,
            timezone: $timezone,
            excludingTripId: $trip->id,
        );

        $hasConflict = $hasScheduleConflict || $isOnActiveTrip;
        $isUnavailable = ! $isAvailable;
        // Flutter: needsConfirmation = !isAvailable || isOnActiveTrip || hasScheduleConflict
        $needsConfirmation = $isUnavailable || $isOnActiveTrip || $hasScheduleConflict;

        return new DriverRecommendation(
            driver: $driver,
            tier: $this->tier($isAvailable, $hasScheduleConflict, $favoriteMatch),
            hasFavoriteMatch: $favoriteMatch,
            hasConflict: $hasConflict,
            isOnActiveTrip: $isOnActiveTrip,
            isUnavailable: $isUnavailable,
            needsConfirmation: $needsConfirmation,
            tripsThisWeek: $tripsThisWeek,
        );
    }

    private static function compareHqDistance(?int $left, ?int $right): int
    {
        if ($left === null && $right === null) {
            return 0;
        }
        if ($left === null) {
            return 1;
        }
        if ($right === null) {
            return -1;
        }

        return $left <=> $right;
    }

    private function tier(bool $isAvailable, bool $hasScheduleConflict, bool $favoriteMatch): int
    {
        if ($isAvailable && ! $hasScheduleConflict && $favoriteMatch) {
            return 0;
        }
        if ($isAvailable && ! $hasScheduleConflict) {
            return 1;
        }

        return 2;
    }

    /**
     * @param  list<Trip>  $trips
     */
    private function driverHasActiveTrip(string $driverId, array $trips): bool
    {
        foreach ($trips as $trip) {
            if ($trip->driverId === $driverId && $this->inProgressSpec->isSatisfiedBy($trip->status)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @param  list<Trip>  $trips
     */
    private function countTripsThisWeek(
        string $driverId,
        array $trips,
        DateTimeImmutable $now,
        DateTimeZone $timezone,
        ?string $excludingTripId,
    ): int {
        $week = $this->periods->withTimezone($timezone);
        $count = 0;
        foreach ($trips as $trip) {
            if ($trip->driverId !== $driverId) {
                continue;
            }
            if ($excludingTripId !== null && $trip->id === $excludingTripId) {
                continue;
            }
            if ($trip->status === TripStatus::Cancelled) {
                continue;
            }
            if ($week->includes($trip->scheduledAt, $now)) {
                $count++;
            }
        }

        return $count;
    }
}
