<?php

declare(strict_types=1);

namespace App\Application\TripRequests\DTOs;

use App\Domain\Enums\TripRequestListBucket;
use App\Domain\Enums\TripRequestStatus;
use DateTimeImmutable;

final readonly class ListMineTripRequestsData
{
    public function __construct(
        public string $employeeId,
        public ?TripRequestStatus $status,
        public ?DateTimeImmutable $dateFrom,
        public ?DateTimeImmutable $dateTo,
        public int $page = 1,
        public int $perPage = 15,
        public ?TripRequestListBucket $bucket = null,
        public bool $awaitingConfirmation = false,
    ) {}
}
