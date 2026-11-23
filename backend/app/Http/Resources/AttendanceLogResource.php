<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Models\AttendanceLog;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AttendanceLog
 */
final class AttendanceLogResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var AttendanceLog $log */
        $log = $this->resource;

        return [
            'id' => $log->id,
            'driver_id' => $log->driver_id,
            'work_date' => $log->workDateString(),
            'status' => $log->status(),
            'checked_in_at' => $log->checked_in_at?->toIso8601String(),
            'check_in_lat' => $log->check_in_lat,
            'check_in_lng' => $log->check_in_lng,
            'check_in_accuracy_m' => $log->check_in_accuracy_m,
            'check_in_distance_m' => $log->check_in_distance_m,
            'checked_out_at' => $log->checked_out_at?->toIso8601String(),
            'check_out_lat' => $log->check_out_lat,
            'check_out_lng' => $log->check_out_lng,
            'check_out_accuracy_m' => $log->check_out_accuracy_m,
            'check_out_distance_m' => $log->check_out_distance_m,
            'on_site_hours' => $log->onSiteHours(),
            'source' => $log->source->value,
            'adjusted_by' => $log->adjusted_by,
            'adjustment_reason' => $log->adjustment_reason,
        ];
    }
}
