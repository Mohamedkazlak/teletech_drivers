<?php

declare(strict_types=1);

namespace App\Application\Attendance;

use App\Application\Attendance\DTOs\ListAttendanceData;
use App\Domain\Entities\AttendanceDay;
use App\Domain\Enums\AttendanceListStatus;
use App\Domain\Services\AttendanceCalendar;
use App\Domain\Services\AttendanceClock;
use App\Domain\Services\FleetPeriodRange;
use App\Models\AttendanceLog;
use App\Models\User;
use DateTimeImmutable;
use Illuminate\Support\Collection;

/**
 * Builds present and absent days for a Cairo range.
 * Absent is computed: a working day with no attendance row.
 */
final class AttendanceDayBuilder
{
    public function __construct(
        private readonly AttendanceClock $clock,
        private readonly AttendanceCalendar $calendar,
        private readonly FleetPeriodRange $periods,
    ) {}

    /**
     * @return array{0: string, 1: string}
     */
    public function range(ListAttendanceData $data): array
    {
        if ($data->dateFrom !== null && $data->dateTo !== null) {
            return [min($data->dateFrom, $data->dateTo), max($data->dateFrom, $data->dateTo)];
        }

        if ($data->period !== null) {
            $window = $this->periods->containing($data->period, $data->periodDate);
            $end = $window['end_exclusive']->modify('-1 day')->format('Y-m-d');

            return [$window['start']->format('Y-m-d'), $end];
        }

        if ($data->date !== null) {
            return [$data->date, $data->date];
        }

        $today = $this->clock->today();

        return [$today, $today];
    }

    /**
     * @param  Collection<int, User>  $drivers
     * @return list<AttendanceDay>
     */
    public function build(Collection $drivers, string $start, string $end, ?AttendanceListStatus $status): array
    {
        if ($drivers->isEmpty()) {
            return [];
        }

        $ids = $drivers->modelKeys();
        $logs = AttendanceLog::query()
            ->whereIn('driver_id', $ids)
            ->whereDate('work_date', '>=', $start)
            ->whereDate('work_date', '<=', $end)
            ->get()
            ->groupBy(static fn (AttendanceLog $log): string => (string) $log->driver_id);

        $days = [];
        foreach ($drivers as $driver) {
            $byDate = [];
            foreach ($logs->get($driver->id, collect()) as $log) {
                $byDate[$log->workDateString()] = $log;
            }

            $cursor = $this->clock->startOfDay($start);
            $last = $this->clock->startOfDay($end);
            $createdAt = $driver->created_at instanceof \DateTimeInterface
                ? DateTimeImmutable::createFromInterface($driver->created_at)
                : $this->clock->now();
            $createdOn = $this->clock->workDate($createdAt);
            $working = array_flip($this->calendar->workingDays($start, $end, $createdAt));

            while ($cursor <= $last) {
                $date = $cursor->format('Y-m-d');
                $cursor = $cursor->modify('+1 day');
                /** @var AttendanceLog|null $log */
                $log = $byDate[$date] ?? null;
                if ($log !== null) {
                    $day = $this->fromLog($driver, $log);
                } elseif ($date >= $createdOn && isset($working[$date])) {
                    $day = $this->absent($driver, $date);
                } else {
                    continue;
                }

                if ($status !== null && ! $this->matches($day, $status)) {
                    continue;
                }
                $days[] = $day;
            }
        }

        usort($days, static function (AttendanceDay $a, AttendanceDay $b): int {
            $date = $b->workDate <=> $a->workDate;
            if ($date !== 0) {
                return $date;
            }

            return strcasecmp($a->driverNameEn, $b->driverNameEn);
        });

        return $days;
    }

    /**
     * @param  list<AttendanceDay>  $days
     * @return array{days_present: int, days_absent: int, total_on_site_hours: float}
     */
    public function totals(array $days): array
    {
        $present = 0;
        $absent = 0;
        $hours = 0.0;
        foreach ($days as $day) {
            if ($day->status === 'absent') {
                $absent++;

                continue;
            }
            $present++;
            $hours += $day->onSiteHours ?? 0.0;
        }

        return [
            'days_present' => $present,
            'days_absent' => $absent,
            'total_on_site_hours' => round($hours, 2),
        ];
    }

    private function matches(AttendanceDay $day, AttendanceListStatus $status): bool
    {
        return match ($status) {
            AttendanceListStatus::Present => $day->status !== 'absent',
            AttendanceListStatus::Absent => $day->status === 'absent',
            AttendanceListStatus::CheckedIn => $day->status === 'checked_in',
            AttendanceListStatus::CheckedOut => $day->status === 'checked_out',
        };
    }

    private function fromLog(User $driver, AttendanceLog $log): AttendanceDay
    {
        return new AttendanceDay(
            driverId: (string) $driver->id,
            driverNameEn: (string) $driver->name_en,
            driverNameAr: $driver->name_ar,
            workDate: $log->workDateString(),
            status: $log->status(),
            logId: (string) $log->id,
            checkedInAt: $log->checked_in_at?->toIso8601String(),
            checkedOutAt: $log->checked_out_at?->toIso8601String(),
            onSiteHours: $log->onSiteHours(),
            checkInDistanceM: $log->check_in_distance_m,
            source: $log->source->value,
            adjustmentReason: $log->adjustment_reason,
        );
    }

    private function absent(User $driver, string $date): AttendanceDay
    {
        return new AttendanceDay(
            driverId: (string) $driver->id,
            driverNameEn: (string) $driver->name_en,
            driverNameAr: $driver->name_ar,
            workDate: $date,
            status: 'absent',
            logId: null,
            checkedInAt: null,
            checkedOutAt: null,
            onSiteHours: null,
            checkInDistanceM: null,
            source: null,
            adjustmentReason: null,
        );
    }
}
