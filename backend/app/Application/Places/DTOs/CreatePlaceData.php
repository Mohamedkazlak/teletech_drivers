<?php

declare(strict_types=1);

namespace App\Application\Places\DTOs;

final readonly class CreatePlaceData
{
    public function __construct(
        public string $nameEn,
        public string $nameAr,
        public ?float $latitude,
        public ?float $longitude,
        public ?string $address,
        public bool $isHeadquarters,
        public bool $isActive,
    ) {}
}
