<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use DateTimeImmutable;

final readonly class TrackingPoint
{
    public function __construct(
        public float $lat,
        public float $lng,
        public DateTimeImmutable $recordedAt,
    ) {}
}
