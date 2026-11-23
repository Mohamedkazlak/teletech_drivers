<?php

declare(strict_types=1);

namespace App\Application\Trips\DTOs;

use App\Domain\Enums\CreatedTripListBucket;

final readonly class ListCreatedByMeTripsData
{
    public function __construct(
        public string $createdBy,
        public ?CreatedTripListBucket $bucket,
        public int $page = 1,
        public int $perPage = 15,
    ) {}
}
