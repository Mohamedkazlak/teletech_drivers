<?php

declare(strict_types=1);

namespace App\Domain\Entities;

final readonly class TripPassenger
{
    public function __construct(
        public string $employeeId,
        public string $nameEn,
        public ?string $nameAr,
        public ?string $phone,
        public ?string $branch,
        public string $requestId,
        public PlaceSnapshot $pickup,
        public PlaceSnapshot $destination,
    ) {}
}
