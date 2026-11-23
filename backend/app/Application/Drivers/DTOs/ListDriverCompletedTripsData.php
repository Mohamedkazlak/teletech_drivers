<?php

declare(strict_types=1);

namespace App\Application\Drivers\DTOs;

final readonly class ListDriverCompletedTripsData
{
    public function __construct(
        public string $driverId,
        public ?string $period,
        public ?string $date,
        public int $page,
        public int $perPage,
    ) {}
}
