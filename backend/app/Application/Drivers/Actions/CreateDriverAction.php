<?php

declare(strict_types=1);

namespace App\Application\Drivers\Actions;

use App\Application\Contracts\PasswordHasherInterface;
use App\Application\Drivers\DTOs\CreateDriverData;
use App\Domain\Entities\Driver;
use App\Domain\Repositories\DriverRepositoryInterface;

final class CreateDriverAction
{
    public function __construct(
        private readonly DriverRepositoryInterface $drivers,
        private readonly PasswordHasherInterface $passwordHasher,
    ) {}

    public function execute(CreateDriverData $data): Driver
    {
        return $this->drivers->create(
            nameEn: $data->nameEn,
            nameAr: $data->nameAr,
            email: $data->email,
            passwordHash: $this->passwordHasher->hash($data->password),
            phone: $data->phone,
            nationalId: $data->nationalId,
            carLicense: $data->carLicense,
            personalLicense: $data->personalLicense,
            favoritePlaceIds: $data->favoritePlaceIds,
        );
    }
}
