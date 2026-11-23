<?php

declare(strict_types=1);

namespace App\Application\Drivers\Actions;

use App\Application\Drivers\DTOs\ListDriverCompletedTripsData;
use App\Domain\Entities\DriverCompletedTrip;
use App\Domain\Entities\Trip;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Services\StatsAggregator;
use App\Domain\Shared\PaginatedResult;

final class ListDriverCompletedTripsAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
    ) {}

    /**
     * @return PaginatedResult<DriverCompletedTrip>
     */
    public function execute(ListDriverCompletedTripsData $data): PaginatedResult
    {
        $page = $this->trips->paginateCompletedByDriver(
            $data->driverId,
            $data->period,
            $data->date,
            $data->page,
            $data->perPage,
        );

        $items = array_map(
            fn (Trip $trip): DriverCompletedTrip => new DriverCompletedTrip(
                id: $trip->id,
                scheduledAt: $trip->scheduledAt,
                goingStartedAt: $trip->goingStartedAt,
                finishedAt: $trip->finishedAt,
                pickupSummary: $trip->pickupSummary,
                destinationSummary: $trip->destinationSummary,
                durationSeconds: StatsAggregator::durationSeconds($trip->goingStartedAt, $trip->finishedAt),
                distanceKm: StatsAggregator::kilometers($trip->totalDistanceM),
                confirmationStatus: $trip->confirmationStatus?->value,
                driverShowedUp: $trip->driverShowedUp,
            ),
            $page->items,
        );

        return new PaginatedResult(
            items: $items,
            total: $page->total,
            page: $page->page,
            perPage: $page->perPage,
        );
    }
}
