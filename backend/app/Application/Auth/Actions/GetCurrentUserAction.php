<?php

declare(strict_types=1);

namespace App\Application\Auth\Actions;

use App\Domain\Entities\User;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\UserRepositoryInterface;

final class GetCurrentUserAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
    ) {}

    public function execute(string $userId): User
    {
        $user = $this->users->findById($userId);

        if ($user === null) {
            throw new UserNotFoundException;
        }

        return $user;
    }
}
