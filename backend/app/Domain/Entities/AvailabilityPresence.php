<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\AvailabilityStatus;
use DateTimeImmutable;

/** One approved available or finished_today request, used to decide the Cairo day. */
final readonly class AvailabilityPresence
{
    public function __construct(
        public string $driverId,
        public AvailabilityStatus $status,
        public DateTimeImmutable $requestedAt,
    ) {}
}
