<?php

declare(strict_types=1);

namespace App\Domain\Services;

use DateTimeImmutable;

/** Resolved departure for one Cairo day. isDefault is not printed. */
final readonly class DayDeparture
{
    public function __construct(
        public ?DateTimeImmutable $at,
        public bool $isDefault,
    ) {}
}
