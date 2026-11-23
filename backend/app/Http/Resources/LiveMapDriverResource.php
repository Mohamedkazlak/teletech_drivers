<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\LiveMapDriver;
use App\Http\Support\JsonNumber;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin LiveMapDriver
 */
final class LiveMapDriverResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var LiveMapDriver $item */
        $item = $this->resource;
        $trip = $item->trip;

        return [
            'driver' => (new DriverSummaryResource($item->driver))->resolve(),
            'is_available' => $item->driver->user->availabilityStatus->value === 'available',
            'state' => $item->state->value,
            'trip' => $trip === null ? null : [
                'id' => $trip->id,
                'status' => $trip->status->value,
                'pickup_summary' => $trip->pickupSummary,
                'destination_summary' => $trip->destinationSummary,
                'scheduled_at' => $trip->scheduledAt->format(DATE_ATOM),
                'going_started_at' => $trip->goingStartedAt?->format(DATE_ATOM),
            ],
            'lat' => JsonNumber::orNull($item->lat),
            'lng' => JsonNumber::orNull($item->lng),
            'heading' => $item->heading,
            'speed' => $item->speed,
            'accuracy' => $item->accuracy,
            'updated_at' => $item->updatedAt?->format(DATE_ATOM),
            'last_seen_at' => $item->updatedAt?->format(DATE_ATOM),
            'is_stale' => $item->isStale,
            'is_tracking' => $item->isTracking,
        ];
    }
}
