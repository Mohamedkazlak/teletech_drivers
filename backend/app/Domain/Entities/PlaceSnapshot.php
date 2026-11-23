<?php

declare(strict_types=1);

namespace App\Domain\Entities;

final readonly class PlaceSnapshot
{
    public function __construct(
        public ?string $placeId,
        public string $name,
        public ?float $lat,
        public ?float $lng,
        public ?string $address,
    ) {}
}
