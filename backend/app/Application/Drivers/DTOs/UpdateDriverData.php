<?php

declare(strict_types=1);

namespace App\Application\Drivers\DTOs;

final readonly class UpdateDriverData
{
    /**
     * @param  list<string>  $favoritePlaceIds
     */
    public function __construct(
        public string $id,
        public string $nameEn,
        public ?string $nameAr,
        public ?string $phone,
        public string $nationalId,
        public string $carLicense,
        public string $personalLicense,
        public array $favoritePlaceIds,
        public bool $isActive,
        public ?string $password,
    ) {}
}
