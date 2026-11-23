<?php

declare(strict_types=1);

namespace App\Domain\Reports;

/** One sheet line. departureIsDefault is internal and is not printed. */
final readonly class DriverMovementRow
{
    public function __construct(
        public string $dayNumber,
        public string $weekday,
        public string $date,
        public string $arrival,
        public string $departure,
        public bool $departureIsDefault,
        public string $from,
        public string $to,
        public string $started,
        public string $ended,
        public bool $friday,
        public bool $leading,
    ) {}
}
