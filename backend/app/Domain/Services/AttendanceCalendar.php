<?php

declare(strict_types=1);

namespace App\Domain\Services;

use DateTimeImmutable;

/**
 * Working days a driver can be absent: from the later of the range start
 * and the driver's Cairo created_at, through today, skipping weekly off days.
 */
final class AttendanceCalendar
{
    public function __construct(
        private readonly AttendanceClock $clock,
    ) {}

    /**
     * @return list<string> Y-m-d, ascending
     */
    public function workingDays(
        string $rangeStart,
        string $rangeEnd,
        DateTimeImmutable $driverCreatedAt,
        ?string $today = null,
    ): array {
        $today ??= $this->clock->today();
        $createdOn = $this->clock->workDate($driverCreatedAt);
        $start = max($rangeStart, $createdOn);
        $end = min($rangeEnd, $today);
        if ($start > $end) {
            return [];
        }

        $days = [];
        $cursor = $this->clock->startOfDay($start);
        $last = $this->clock->startOfDay($end);
        while ($cursor <= $last) {
            $date = $cursor->format('Y-m-d');
            if (! $this->clock->isWeeklyOff($date)) {
                $days[] = $date;
            }
            $cursor = $cursor->modify('+1 day');
        }

        return $days;
    }
}
