<?php

declare(strict_types=1);

namespace App\Application\Drivers\DTOs;

final readonly class CreateDriverData
{
    /**
     * @param  list<string>  $favoritePlaceIds
     */
    public function __construct(
        public string $nameEn,
        public string $nameAr,
        public string $email,
        public string $password,
        public ?string $phone,
        public string $nationalId,
        public string $carLicense,
        public string $personalLicense,
        public array $favoritePlaceIds,
    ) {}
}
