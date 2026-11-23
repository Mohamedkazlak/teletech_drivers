<?php

declare(strict_types=1);

namespace App\Application\Attendance\Actions;

use App\Domain\Enums\UserRole;
use App\Domain\Services\AttendanceClock;
use App\Models\AttendanceLog;
use App\Models\User;

final class TodayAttendanceSummaryAction
{
    public function __construct(
        private readonly AttendanceClock $clock,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function execute(): array
    {
        $workDate = $this->clock->today();
        $offDay = $this->clock->isWeeklyOff($workDate);
        $drivers = User::query()->where('role', UserRole::Driver)->orderBy('name_en')->get();
        $logs = AttendanceLog::query()
            ->whereDate('work_date', $workDate)
            ->get()
            ->keyBy(static fn (AttendanceLog $log): string => (string) $log->driver_id);

        $present = [];
        $checkedIn = [];
        $checkedOut = [];
        $absent = [];

        foreach ($drivers as $driver) {
            /** @var AttendanceLog|null $log */
            $log = $logs->get($driver->id);
            $row = $this->row($driver, $log);
            if ($log === null) {
                if (! $offDay) {
                    $absent[] = $row;
                }

                continue;
            }
            $present[] = $row;
            if ($log->isOpen()) {
                $checkedIn[] = $row;
            } else {
                $checkedOut[] = $row;
            }
        }

        return [
            'work_date' => $workDate,
            'off_day' => $offDay,
            'counts' => [
                'present' => count($present),
                'checked_in' => count($checkedIn),
                'checked_out' => count($checkedOut),
                'absent' => count($absent),
            ],
            'present' => $present,
            'checked_in' => $checkedIn,
            'checked_out' => $checkedOut,
            'absent' => $absent,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function row(User $driver, ?AttendanceLog $log): array
    {
        return [
            'id' => (string) $driver->id,
            'name_en' => $driver->name_en,
            'name_ar' => $driver->name_ar,
            'checked_in_at' => $log?->checked_in_at?->toIso8601String(),
            'checked_out_at' => $log?->checked_out_at?->toIso8601String(),
            'check_in_distance_m' => $log?->check_in_distance_m,
            'status' => $log === null ? 'absent' : $log->status(),
        ];
    }
}
