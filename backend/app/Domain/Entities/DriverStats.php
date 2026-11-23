<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use DateTimeImmutable;

final readonly class DriverStats
{
    /**
     * @param  list<StatsBucket>  $breakdown
     */
    public function __construct(
        public string $period,
        public ?DateTimeImmutable $from,
        public ?DateTimeImmutable $to,
        public int $trips,
        public int $totalSeconds,
        public int $totalDistanceM,
        public array $breakdown,
    ) {}
}
