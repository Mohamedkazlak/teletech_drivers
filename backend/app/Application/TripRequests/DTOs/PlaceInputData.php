<?php

declare(strict_types=1);

namespace App\Application\TripRequests\DTOs;

final readonly class PlaceInputData
{
    public function __construct(
        public ?string $placeId,
        public ?string $name,
        public ?float $lat,
        public ?float $lng,
        public ?string $address,
    ) {}

    public function isPlaceId(): bool
    {
        return $this->placeId !== null && $this->placeId !== '';
    }
}
