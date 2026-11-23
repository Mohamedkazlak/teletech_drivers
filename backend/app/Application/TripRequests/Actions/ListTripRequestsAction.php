<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Actions;

use App\Application\TripRequests\DTOs\ListTripRequestsData;
use App\Domain\Entities\TripRequest;
use App\Domain\Repositories\TripRequestRepositoryInterface;
use App\Domain\Shared\PaginatedResult;

final class ListTripRequestsAction
{
    public function __construct(
        private readonly TripRequestRepositoryInterface $tripRequests,
    ) {}

    /**
     * @return PaginatedResult<TripRequest>
     */
    public function execute(ListTripRequestsData $data): PaginatedResult
    {
        return $this->tripRequests->paginateAdmin(
            status: $data->status,
            hasTrip: $data->hasTrip,
            dateFrom: $data->dateFrom,
            dateTo: $data->dateTo,
            employeeId: $data->employeeId,
            search: $data->search,
            page: $data->page,
            perPage: $data->perPage,
            branch: $data->branch,
            stage: $data->stage,
            period: $data->period,
            periodDate: $data->periodDate,
        );
    }
}
