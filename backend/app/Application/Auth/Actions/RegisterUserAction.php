<?php

declare(strict_types=1);

namespace App\Application\Auth\Actions;

use App\Application\Auth\DTOs\RegisterUserData;
use App\Application\Auth\Results\AuthTokenResult;
use App\Application\Contracts\PasswordHasherInterface;
use App\Application\Contracts\TokenIssuerInterface;
use App\Domain\Repositories\UserRepositoryInterface;

final class RegisterUserAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
        private readonly PasswordHasherInterface $passwordHasher,
        private readonly TokenIssuerInterface $tokenIssuer,
    ) {}

    public function execute(RegisterUserData $data): AuthTokenResult
    {
        $user = $this->users->createEmployee(
            nameEn: $data->nameEn,
            nameAr: $data->nameAr,
            email: $data->email,
            passwordHash: $this->passwordHasher->hash($data->password),
            phone: $data->phone,
            branch: $data->branch,
        );

        $token = $this->tokenIssuer->issue($user);

        return new AuthTokenResult($user, $token);
    }
}
