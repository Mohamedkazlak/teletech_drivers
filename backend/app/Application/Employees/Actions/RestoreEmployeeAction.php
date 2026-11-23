<?php

declare(strict_types=1);

namespace App\Application\Employees\Actions;

use App\Domain\Entities\User;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\UserRepositoryInterface;

final class RestoreEmployeeAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
    ) {}

    public function execute(string $employeeId): User
    {
        $existing = $this->users->findById($employeeId, withTrashed: true);

        if ($existing === null || $existing->role !== UserRole::Employee) {
            throw new UserNotFoundException;
        }

        return $this->users->restore($employeeId);
    }
}
