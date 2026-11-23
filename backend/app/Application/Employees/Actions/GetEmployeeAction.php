<?php

declare(strict_types=1);

namespace App\Application\Employees\Actions;

use App\Domain\Entities\User;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\UserRepositoryInterface;

final class GetEmployeeAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
    ) {}

    public function execute(string $id, bool $withTrashed = false): User
    {
        $user = $this->users->findById($id, $withTrashed);

        if ($user === null || $user->role !== UserRole::Employee) {
            throw new UserNotFoundException;
        }

        return $user;
    }
}
