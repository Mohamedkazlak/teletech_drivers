<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Domain\Entities\DriverRecommendation;
use App\Domain\Enums\TripStatus;
use App\Domain\Exceptions\StateConflictException;
use App\Domain\Exceptions\TripNotFoundException;
use App\Domain\Repositories\DriverRepositoryInterface;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Services\DriverRecommendationService;
use DateTimeImmutable;
use DateTimeZone;

final class GetDriverRecommendationsAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly DriverRepositoryInterface $drivers,
        private readonly DriverRecommendationService $recommendations,
    ) {}

    /**
     * @return list<DriverRecommendation>
     */
    public function execute(string $tripId): array
    {
        $trip = $this->trips->findById($tripId);
        if ($trip === null) {
            throw new TripNotFoundException;
        }

        if ($trip->status !== TripStatus::Unassigned && $trip->status !== TripStatus::Assigned) {
            throw new StateConflictException(
                'Driver recommendations are only available for unassigned or assigned trips.',
            );
        }

        $timezone = new DateTimeZone((string) config('teletech.business_timezone', 'UTC'));
        $now = DateTimeImmutable::createFromInterface(now());
        $drivers = $this->drivers->listActiveDrivers();

        return $this->recommendations->recommend(
            trip: $trip,
            drivers: $drivers,
            allTrips: $this->trips->listAllForRecommendations(),
            tripPlaceIds: $this->trips->linkedPlaceIds($tripId),
            now: $now,
            timezone: $timezone,
        );
    }
}
