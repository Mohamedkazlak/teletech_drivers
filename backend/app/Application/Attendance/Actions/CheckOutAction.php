<?php

declare(strict_types=1);

namespace App\Application\Attendance\Actions;

use App\Application\Attendance\DTOs\AttendanceScanData;
use App\Application\Realtime\RealtimePublisher;
use App\Domain\Exceptions\AttendanceRejectedException;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Services\AttendanceClock;
use App\Domain\Services\AttendanceScanGuard;
use App\Models\AttendanceLog;
use Illuminate\Support\Facades\DB;

final class CheckOutAction
{
    public function __construct(
        private readonly AttendanceScanGuard $guard,
        private readonly AttendanceClock $clock,
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(AttendanceScanData $data): AttendanceLog
    {
        $distance = $this->guard->assertAcceptable(
            $data->qrPayload,
            $data->lat,
            $data->lng,
            $data->accuracyM,
            $data->isMocked,
        );

        $log = DB::transaction(function () use ($data, $distance): AttendanceLog {
            $workDate = $this->clock->today();
            $existing = AttendanceLog::query()
                ->where('driver_id', $data->driverId)
                ->whereDate('work_date', $workDate)
                ->lockForUpdate()
                ->first();

            if ($existing === null) {
                throw new AttendanceRejectedException(
                    'not_checked_in',
                    __('messages.attendance_not_checked_in'),
                    409,
                );
            }

            if ($existing->checked_out_at !== null) {
                throw new AttendanceRejectedException(
                    'already_checked_out',
                    __('messages.attendance_already_checked_out'),
                    409,
                );
            }

            if ($this->trips->listInProgress($data->driverId) !== []) {
                throw new AttendanceRejectedException(
                    'active_trip',
                    __('messages.attendance_active_trip'),
                    409,
                );
            }

            $existing->forceFill([
                'checked_out_at' => now(),
                'check_out_lat' => $data->lat,
                'check_out_lng' => $data->lng,
                'check_out_accuracy_m' => $data->accuracyM,
                'check_out_distance_m' => $distance,
            ])->save();

            return $existing->refresh();
        });

        $this->realtime->attendance('attendance.checked_out', $log);

        return $log;
    }
}
