<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Trips\DTOs\ListCreatedByMeTripsData;
use App\Domain\Entities\Trip;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Shared\PaginatedResult;

final class ListCreatedByMeTripsAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
    ) {}

    /**
     * @return PaginatedResult<Trip>
     */
    public function execute(ListCreatedByMeTripsData $data): PaginatedResult
    {
        return $this->trips->paginateCreatedBy(
            createdBy: $data->createdBy,
            bucket: $data->bucket,
            page: $data->page,
            perPage: $data->perPage,
        );
    }
}
