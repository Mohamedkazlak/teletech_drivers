<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\AttendanceDay;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AttendanceDay
 */
final class AttendanceDayResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var AttendanceDay $day */
        $day = $this->resource;

        return [
            'driver_id' => $day->driverId,
            'driver_name_en' => $day->driverNameEn,
            'driver_name_ar' => $day->driverNameAr,
            'work_date' => $day->workDate,
            'status' => $day->status,
            'attendance_id' => $day->logId,
            'checked_in_at' => $day->checkedInAt,
            'checked_out_at' => $day->checkedOutAt,
            'on_site_hours' => $day->onSiteHours,
            'check_in_distance_m' => $day->checkInDistanceM,
            'source' => $day->source,
            'adjustment_reason' => $day->adjustmentReason,
        ];
    }
}
