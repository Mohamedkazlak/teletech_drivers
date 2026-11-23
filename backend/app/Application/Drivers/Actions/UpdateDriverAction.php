<?php

declare(strict_types=1);

namespace App\Application\Drivers\Actions;

use App\Application\Contracts\PasswordHasherInterface;
use App\Application\Drivers\DTOs\UpdateDriverData;
use App\Domain\Entities\Driver;
use App\Domain\Repositories\DriverRepositoryInterface;

final class UpdateDriverAction
{
    public function __construct(
        private readonly DriverRepositoryInterface $drivers,
        private readonly PasswordHasherInterface $passwordHasher,
    ) {}

    public function execute(UpdateDriverData $data): Driver
    {
        $passwordHash = $data->password === null
            ? null
            : $this->passwordHasher->hash($data->password);

        return $this->drivers->update(
            id: $data->id,
            nameEn: $data->nameEn,
            nameAr: $data->nameAr,
            phone: $data->phone,
            nationalId: $data->nationalId,
            carLicense: $data->carLicense,
            personalLicense: $data->personalLicense,
            favoritePlaceIds: $data->favoritePlaceIds,
            isActive: $data->isActive,
            passwordHash: $passwordHash,
        );
    }
}
