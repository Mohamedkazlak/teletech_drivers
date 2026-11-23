<?php

declare(strict_types=1);

namespace App\Application\Users\Actions;

use App\Application\Contracts\PasswordHasherInterface;
use App\Application\Contracts\TokenIssuerInterface;
use App\Application\Users\DTOs\ResetUserPasswordData;
use App\Domain\Entities\User;
use App\Domain\Exceptions\CannotActOnSelfException;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\UserRepositoryInterface;

final class ResetUserPasswordAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
        private readonly PasswordHasherInterface $passwordHasher,
        private readonly TokenIssuerInterface $tokenIssuer,
    ) {}

    public function execute(ResetUserPasswordData $data): User
    {
        if ($data->actorId === $data->userId) {
            throw new CannotActOnSelfException;
        }

        $existing = $this->users->findById($data->userId);

        if ($existing === null || $existing->isSoftDeleted()) {
            throw new UserNotFoundException;
        }

        $updated = $this->users->assignTemporaryPassword(
            $data->userId,
            $this->passwordHasher->hash($data->password),
        );
        $this->tokenIssuer->revokeAllTokens($data->userId);

        return $updated;
    }
}
