<?php

declare(strict_types=1);

namespace App\Application\Attendance\Actions;

use App\Domain\Services\AttendanceClock;
use App\Models\AttendanceLog;

final class ShowTodayAttendanceAction
{
    public function __construct(
        private readonly AttendanceClock $clock,
    ) {}

    /**
     * @return array{work_date: string, status: string, attendance: ?AttendanceLog}
     */
    public function execute(string $driverId): array
    {
        $workDate = $this->clock->today();
        $log = AttendanceLog::query()
            ->where('driver_id', $driverId)
            ->whereDate('work_date', $workDate)
            ->first();

        return [
            'work_date' => $workDate,
            'status' => $log === null ? 'not_checked_in' : $log->status(),
            'attendance' => $log,
        ];
    }
}
