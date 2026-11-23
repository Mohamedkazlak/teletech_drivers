<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Trips\DTOs\ListTripsData;
use App\Domain\Entities\Trip;
use App\Domain\Enums\UserRole;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Shared\PaginatedResult;

final class ListTripsAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
    ) {}

    /**
     * @return PaginatedResult<Trip>
     */
    public function execute(ListTripsData $data, UserRole $actorRole, string $actorId): PaginatedResult
    {
        return $this->trips->paginate(
            status: $data->status,
            driverId: $data->driverId,
            dateFrom: $data->dateFrom,
            dateTo: $data->dateTo,
            page: $data->page,
            perPage: $data->perPage,
            stage: $data->stage,
            branch: $data->branch,
            driverShowedUp: $data->driverShowedUp,
            period: $data->period,
            periodDate: $data->periodDate,
            finishedPeriod: $data->finishedPeriod,
            unconfirmed: $data->unconfirmed,
            lifecycle: $data->lifecycle,
            excludeRequesterId: $actorRole === UserRole::DriversAdmin ? $actorId : null,
        );
    }
}
