<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Actions;

use App\Application\TripRequests\DTOs\ListMineTripRequestsData;
use App\Domain\Entities\TripRequest;
use App\Domain\Repositories\TripRequestRepositoryInterface;
use App\Domain\Shared\PaginatedResult;

final class ListMineTripRequestsAction
{
    public function __construct(
        private readonly TripRequestRepositoryInterface $tripRequests,
    ) {}

    /**
     * @return PaginatedResult<TripRequest>
     */
    public function execute(ListMineTripRequestsData $data): PaginatedResult
    {
        return $this->tripRequests->paginateMine(
            employeeId: $data->employeeId,
            status: $data->status,
            dateFrom: $data->dateFrom,
            dateTo: $data->dateTo,
            page: $data->page,
            perPage: $data->perPage,
            bucket: $data->bucket,
            awaitingConfirmation: $data->awaitingConfirmation,
        );
    }
}
