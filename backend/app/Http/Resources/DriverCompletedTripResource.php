<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\DriverCompletedTrip;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin DriverCompletedTrip
 */
final class DriverCompletedTripResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var DriverCompletedTrip $trip */
        $trip = $this->resource;

        return [
            'id' => $trip->id,
            'scheduled_at' => $trip->scheduledAt->format(DATE_ATOM),
            'going_started_at' => $trip->goingStartedAt?->format(DATE_ATOM),
            'finished_at' => $trip->finishedAt?->format(DATE_ATOM),
            'pickup_summary' => $trip->pickupSummary,
            'destination_summary' => $trip->destinationSummary,
            'duration_seconds' => $trip->durationSeconds,
            'distance_km' => $trip->distanceKm,
            'confirmation_status' => $trip->confirmationStatus,
            'driver_showed_up' => $trip->driverShowedUp,
        ];
    }
}
