<?php

declare(strict_types=1);

namespace App\Application\Employees\Actions;

use App\Application\Employees\DTOs\ListEmployeesData;
use App\Domain\Entities\User;
use App\Domain\Repositories\UserRepositoryInterface;
use App\Domain\Shared\PaginatedResult;

final class ListEmployeesAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
    ) {}

    /**
     * @return PaginatedResult<User>
     */
    public function execute(ListEmployeesData $data): PaginatedResult
    {
        return $this->users->paginateEmployees(
            isActive: $data->isActive,
            branch: $data->branch,
            search: $data->search,
            includeDeleted: $data->includeDeleted,
            page: $data->page,
            perPage: $data->perPage,
        );
    }
}
