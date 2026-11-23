<?php

declare(strict_types=1);

namespace App\Application\Drivers\Actions;

use App\Application\Drivers\DTOs\ListDriversData;
use App\Domain\Entities\Driver;
use App\Domain\Repositories\DriverRepositoryInterface;
use App\Domain\Shared\PaginatedResult;

final class ListDriversAction
{
    public function __construct(
        private readonly DriverRepositoryInterface $drivers,
    ) {}

    /**
     * @return PaginatedResult<Driver>
     */
    public function execute(ListDriversData $data): PaginatedResult
    {
        return $this->drivers->paginate(
            isActive: $data->isActive,
            attendance: $data->attendance,
            search: $data->search,
            includeDeleted: $data->includeDeleted,
            page: $data->page,
            perPage: $data->perPage,
        );
    }
}
