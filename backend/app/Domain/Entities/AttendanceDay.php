<?php

declare(strict_types=1);

namespace App\Domain\Entities;

/**
 * One Cairo working day for one driver. Absent days have no log.
 */
final readonly class AttendanceDay
{
    public function __construct(
        public string $driverId,
        public string $driverNameEn,
        public ?string $driverNameAr,
        public string $workDate,
        public string $status,
        public ?string $logId,
        public ?string $checkedInAt,
        public ?string $checkedOutAt,
        public ?float $onSiteHours,
        public ?int $checkInDistanceM,
        public ?string $source,
        public ?string $adjustmentReason,
    ) {}
}
