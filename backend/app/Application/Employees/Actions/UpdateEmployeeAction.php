<?php

declare(strict_types=1);

namespace App\Application\Employees\Actions;

use App\Application\Contracts\PasswordHasherInterface;
use App\Application\Employees\DTOs\UpdateEmployeeData;
use App\Domain\Entities\User;
use App\Domain\Repositories\UserRepositoryInterface;

final class UpdateEmployeeAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
        private readonly PasswordHasherInterface $passwordHasher,
    ) {}

    public function execute(UpdateEmployeeData $data): User
    {
        $passwordHash = $data->password === null
            ? null
            : $this->passwordHasher->hash($data->password);

        return $this->users->updateEmployee(
            id: $data->id,
            nameEn: $data->nameEn,
            nameAr: $data->nameAr,
            phone: $data->phone,
            branch: $data->branch,
            isActive: $data->isActive,
            passwordHash: $passwordHash,
        );
    }
}
