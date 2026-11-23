<?php

declare(strict_types=1);

namespace App\Application\Attendance\DTOs;

use DateTimeImmutable;

final readonly class AdjustAttendanceData
{
    public function __construct(
        public string $actorId,
        public string $driverId,
        public string $workDate,
        public DateTimeImmutable $checkedInAt,
        public ?DateTimeImmutable $checkedOutAt,
        public string $reason,
    ) {}
}
