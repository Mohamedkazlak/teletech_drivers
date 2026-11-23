<?php

declare(strict_types=1);

namespace App\Application\Users\Actions;

use App\Application\Users\DTOs\ListUsersData;
use App\Domain\Entities\User;
use App\Domain\Repositories\UserRepositoryInterface;
use App\Domain\Shared\PaginatedResult;

final class ListUsersAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
    ) {}

    /**
     * @return PaginatedResult<User>
     */
    public function execute(ListUsersData $data): PaginatedResult
    {
        return $this->users->paginateUsers(
            role: $data->role,
            search: $data->search,
            page: $data->page,
            perPage: $data->perPage,
        );
    }
}
