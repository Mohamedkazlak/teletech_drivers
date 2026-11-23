<?php

declare(strict_types=1);

namespace App\Application\Employees\Actions;

use App\Application\Contracts\TokenIssuerInterface;
use App\Domain\Entities\User;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\UserRepositoryInterface;

final class SoftDeleteEmployeeAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
        private readonly TokenIssuerInterface $tokenIssuer,
    ) {}

    public function execute(string $employeeId, string $actorId): User
    {
        $existing = $this->users->findById($employeeId);

        if ($existing === null || $existing->role !== UserRole::Employee) {
            throw new UserNotFoundException;
        }

        $user = $this->users->softDelete($employeeId, $actorId);
        $this->tokenIssuer->revokeAllTokens($employeeId);

        return $user;
    }
}
