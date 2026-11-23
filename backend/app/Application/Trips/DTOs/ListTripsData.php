<?php

declare(strict_types=1);

namespace App\Application\Trips\DTOs;

use App\Domain\Enums\Branch;
use App\Domain\Enums\CreatedTripListBucket;
use App\Domain\Enums\TripLifecycle;
use App\Domain\Enums\TripStage;
use App\Domain\Enums\TripStatus;
use DateTimeImmutable;

final readonly class ListTripsData
{
    public function __construct(
        public ?TripStatus $status,
        public ?string $driverId,
        public ?DateTimeImmutable $dateFrom,
        public ?DateTimeImmutable $dateTo,
        public int $page = 1,
        public int $perPage = 15,
        public ?TripStage $stage = null,
        public ?Branch $branch = null,
        public ?bool $driverShowedUp = null,
        public ?string $period = null,
        public ?string $periodDate = null,
        public ?CreatedTripListBucket $bucket = null,
        public ?string $finishedPeriod = null,
        public ?bool $unconfirmed = null,
        public ?TripLifecycle $lifecycle = null,
    ) {}
}
