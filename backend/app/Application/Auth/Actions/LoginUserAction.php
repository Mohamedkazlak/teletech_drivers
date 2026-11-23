<?php

declare(strict_types=1);

namespace App\Application\Auth\Actions;

use App\Application\Auth\DTOs\LoginUserData;
use App\Application\Auth\Results\AuthTokenResult;
use App\Application\Contracts\PasswordHasherInterface;
use App\Application\Contracts\TokenIssuerInterface;
use App\Domain\Exceptions\InactiveUserException;
use App\Domain\Exceptions\InvalidCredentialsException;
use App\Domain\Repositories\UserRepositoryInterface;

final class LoginUserAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
        private readonly PasswordHasherInterface $passwordHasher,
        private readonly TokenIssuerInterface $tokenIssuer,
    ) {}

    public function execute(LoginUserData $data): AuthTokenResult
    {
        $user = $this->users->findByEmail($data->email);

        if ($user === null || ! $this->passwordHasher->check($data->password, $user->passwordHash)) {
            throw new InvalidCredentialsException;
        }

        if (! $user->canAuthenticate()) {
            throw new InactiveUserException;
        }

        $token = $this->tokenIssuer->issue($user);

        return new AuthTokenResult($user, $token);
    }
}
