<?php

declare(strict_types=1);

namespace App\Application\TripRequests\DTOs;

use App\Domain\Enums\Branch;
use App\Domain\Enums\TripRequestStage;
use App\Domain\Enums\TripRequestStatus;
use DateTimeImmutable;

final readonly class ListTripRequestsData
{
    public function __construct(
        public ?TripRequestStatus $status,
        public ?bool $hasTrip,
        public ?DateTimeImmutable $dateFrom,
        public ?DateTimeImmutable $dateTo,
        public ?string $employeeId,
        public ?string $search,
        public int $page = 1,
        public int $perPage = 15,
        public ?Branch $branch = null,
        public ?TripRequestStage $stage = null,
        public ?string $period = null,
        public ?string $periodDate = null,
    ) {}
}
