<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use DateTimeImmutable;

final readonly class StatsBucket
{
    public function __construct(
        public string $label,
        public DateTimeImmutable $from,
        public DateTimeImmutable $to,
        public int $trips,
        public int $totalSeconds,
        public int $totalDistanceM,
    ) {}
}
