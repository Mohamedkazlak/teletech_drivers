<?php

declare(strict_types=1);

namespace App\Application\Auth\Actions;

use App\Application\Auth\DTOs\ChangePasswordData;
use App\Application\Contracts\PasswordHasherInterface;
use App\Application\Contracts\TokenIssuerInterface;
use App\Domain\Entities\User;
use App\Domain\Exceptions\InactiveUserException;
use App\Domain\Exceptions\InvalidCurrentPasswordException;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\UserRepositoryInterface;

final class ChangePasswordAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
        private readonly PasswordHasherInterface $passwordHasher,
        private readonly TokenIssuerInterface $tokenIssuer,
    ) {}

    public function execute(ChangePasswordData $data): User
    {
        $user = $this->users->findById($data->userId);

        if ($user === null) {
            throw new UserNotFoundException;
        }

        if (! $user->canAuthenticate()) {
            throw new InactiveUserException;
        }

        if (! $this->passwordHasher->check($data->currentPassword, $user->passwordHash)) {
            throw new InvalidCurrentPasswordException;
        }

        $updated = $this->users->updatePassword(
            $data->userId,
            $this->passwordHasher->hash($data->password),
        );
        $this->tokenIssuer->revokeOtherTokens($data->userId);

        return $updated;
    }
}
