<?php

declare(strict_types=1);

namespace App\Application\Attendance\Actions;

use App\Application\Attendance\DTOs\AdjustAttendanceData;
use App\Application\Realtime\RealtimePublisher;
use App\Domain\Enums\AttendanceSource;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\AttendanceRejectedException;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Services\AttendanceClock;
use App\Models\AttendanceLog;
use App\Models\User;
use Illuminate\Support\Facades\DB;

final class AdjustAttendanceAction
{
    public function __construct(
        private readonly AttendanceClock $clock,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(AdjustAttendanceData $data): AttendanceLog
    {
        $log = DB::transaction(function () use ($data): AttendanceLog {
            $driver = User::query()->whereKey($data->driverId)->first();
            if ($driver === null || $driver->role !== UserRole::Driver) {
                throw new UserNotFoundException;
            }

            if ($this->clock->isFuture($data->workDate)) {
                throw new AttendanceRejectedException(
                    'future_date',
                    __('messages.attendance_future_date'),
                );
            }

            $checkInDate = $this->clock->workDate($data->checkedInAt);
            if ($checkInDate !== $data->workDate) {
                throw new AttendanceRejectedException(
                    'work_date_mismatch',
                    __('messages.attendance_work_date_mismatch'),
                );
            }

            if ($data->checkedOutAt !== null && $data->checkedOutAt < $data->checkedInAt) {
                throw new AttendanceRejectedException(
                    'checkout_before_checkin',
                    __('messages.attendance_checkout_before_checkin'),
                );
            }

            $existing = AttendanceLog::query()
                ->where('driver_id', $data->driverId)
                ->whereDate('work_date', $data->workDate)
                ->lockForUpdate()
                ->first();

            $attributes = [
                'checked_in_at' => $data->checkedInAt,
                'checked_out_at' => $data->checkedOutAt,
                'source' => AttendanceSource::Admin,
                'adjusted_by' => $data->actorId,
                'adjustment_reason' => $data->reason,
            ];

            if ($existing === null) {
                $existing = AttendanceLog::query()->create([
                    'driver_id' => $data->driverId,
                    'work_date' => $data->workDate,
                    ...$attributes,
                ]);
            } else {
                $existing->forceFill($attributes)->save();
            }

            return $existing->refresh();
        });

        $this->realtime->attendance('attendance.adjusted', $log);

        return $log;
    }
}
