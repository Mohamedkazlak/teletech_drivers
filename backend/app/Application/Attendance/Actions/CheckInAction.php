<?php

declare(strict_types=1);

namespace App\Application\Attendance\Actions;

use App\Application\Attendance\DTOs\AttendanceScanData;
use App\Application\Realtime\RealtimePublisher;
use App\Domain\Enums\AttendanceSource;
use App\Domain\Exceptions\AttendanceRejectedException;
use App\Domain\Repositories\DriverLocationRepositoryInterface;
use App\Domain\Services\AttendanceClock;
use App\Domain\Services\AttendanceScanGuard;
use App\Models\AttendanceLog;
use DateTimeImmutable;
use Illuminate\Support\Facades\DB;

final class CheckInAction
{
    public function __construct(
        private readonly AttendanceScanGuard $guard,
        private readonly AttendanceClock $clock,
        private readonly DriverLocationRepositoryInterface $locations,
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

            if ($existing !== null) {
                throw new AttendanceRejectedException(
                    'already_checked_in',
                    __('messages.attendance_already_checked_in'),
                    409,
                );
            }

            $log = AttendanceLog::query()->create([
                'driver_id' => $data->driverId,
                'work_date' => $workDate,
                'checked_in_at' => now(),
                'check_in_lat' => $data->lat,
                'check_in_lng' => $data->lng,
                'check_in_accuracy_m' => $data->accuracyM,
                'check_in_distance_m' => $distance,
                'source' => AttendanceSource::Scan,
            ]);

            $this->locations->upsertLastKnownIfNewer(
                $data->driverId,
                $data->lat,
                $data->lng,
                DateTimeImmutable::createFromInterface(now()),
            );

            return $log;
        });

        $this->realtime->attendance('attendance.checked_in', $log);

        return $log;
    }
}
