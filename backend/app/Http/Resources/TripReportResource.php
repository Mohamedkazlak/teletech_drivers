<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\TrackingPoint;
use App\Domain\Entities\TripReport;
use App\Http\Support\JsonNumber;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripReport
 */
final class TripReportResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var TripReport $report */
        $report = $this->resource;

        return [
            'status' => $report->status->value,
            'is_in_progress' => $report->isInProgress,
            'start' => $report->startedAt?->format(DATE_ATOM),
            'finish' => $report->finishedAt?->format(DATE_ATOM),
            'going_duration_seconds' => $report->goingDurationSeconds,
            'waiting_duration_seconds' => $report->waitingDurationSeconds,
            'return_duration_seconds' => $report->returnDurationSeconds,
            'total_duration_seconds' => $report->totalDurationSeconds,
            'going_distance_km' => $report->goingDistanceKm,
            'return_distance_km' => $report->returnDistanceKm,
            'total_distance_km' => $report->totalDistanceKm,
            'going_route' => $report->goingRoute,
            'return_route' => $report->returnRoute,
            'driven_route' => array_map(
                static fn (TrackingPoint $point): array => [
                    'lat' => JsonNumber::orNull($point->lat),
                    'lng' => JsonNumber::orNull($point->lng),
                    'recorded_at' => $point->recordedAt->format(DATE_ATOM),
                ],
                $report->drivenRoute,
            ),
        ];
    }
}
