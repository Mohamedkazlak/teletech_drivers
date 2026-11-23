<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use DateTimeImmutable;

final readonly class Place
{
    public function __construct(
        public string $id,
        public string $nameEn,
        public string $nameAr,
        public ?float $latitude,
        public ?float $longitude,
        public ?string $address,
        public bool $isHeadquarters,
        public bool $isActive,
        public ?DateTimeImmutable $createdAt = null,
    ) {}
}
