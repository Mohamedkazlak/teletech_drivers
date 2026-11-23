<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Trips\DTOs\ListMineTripsData;
use App\Domain\Entities\Trip;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Shared\PaginatedResult;

final class ListMineTripsAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
    ) {}

    /**
     * @return PaginatedResult<Trip>
     */
    public function execute(ListMineTripsData $data): PaginatedResult
    {
        return $this->trips->paginateMine(
            driverId: $data->driverId,
            status: $data->status,
            page: $data->page,
            perPage: $data->perPage,
            statuses: $data->statuses,
            period: $data->period,
            periodDate: $data->periodDate,
        );
    }
}
