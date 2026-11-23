<?php

declare(strict_types=1);

namespace App\Application\Trips\DTOs;

use App\Domain\Enums\TripStatus;

final readonly class ListMineTripsData
{
    /**
     * @param  list<TripStatus>|null  $statuses
     */
    public function __construct(
        public string $driverId,
        public ?TripStatus $status,
        public int $page = 1,
        public int $perPage = 15,
        public ?array $statuses = null,
        public ?string $period = null,
        public ?string $periodDate = null,
    ) {}
}
