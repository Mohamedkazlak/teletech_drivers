<?php

declare(strict_types=1);

namespace App\Application\Employees\Actions;

use App\Application\Contracts\PasswordHasherInterface;
use App\Application\Employees\DTOs\CreateEmployeeData;
use App\Domain\Entities\User;
use App\Domain\Repositories\UserRepositoryInterface;

final class CreateEmployeeAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
        private readonly PasswordHasherInterface $passwordHasher,
    ) {}

    public function execute(CreateEmployeeData $data): User
    {
        return $this->users->createEmployee(
            nameEn: $data->nameEn,
            nameAr: $data->nameAr,
            email: $data->email,
            passwordHash: $this->passwordHasher->hash($data->password),
            phone: $data->phone,
            branch: $data->branch,
            mustChangePassword: true,
        );
    }
}
