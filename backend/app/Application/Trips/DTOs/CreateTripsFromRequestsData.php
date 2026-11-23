<?php

declare(strict_types=1);

namespace App\Application\Trips\DTOs;

use App\Domain\Enums\TripCreationMode;
use DateTimeImmutable;

final readonly class CreateTripsFromRequestsData
{
    /**
     * @param  list<string>  $requestIds
     */
    public function __construct(
        public TripCreationMode $mode,
        public array $requestIds,
        public ?DateTimeImmutable $scheduledAt,
        public string $createdBy,
    ) {}
}
