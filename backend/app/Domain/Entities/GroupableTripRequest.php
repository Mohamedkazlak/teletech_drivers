<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use DateTimeImmutable;

/**
 * Minimal request shape for grouping (pure domain clustering input).
 */
final readonly class GroupableTripRequest
{
    public function __construct(
        public string $id,
        public DateTimeImmutable $requestedAt,
        public ?string $destinationPlaceId,
        public ?float $destinationLat,
        public ?float $destinationLng,
        public string $destinationName,
        public string $pickupName,
        public ?string $requesterNameEn = null,
        public ?string $requesterNameAr = null,
        public ?string $branch = null,
    ) {}
}
