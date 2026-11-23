<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\DriverLocation;
use App\Http\Support\JsonNumber;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin DriverLocation
 */
final class DriverLocationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var DriverLocation $location */
        $location = $this->resource;

        return [
            'driver_id' => $location->driverId,
            'trip_id' => $location->tripId,
            'lat' => JsonNumber::orNull($location->lat),
            'lng' => JsonNumber::orNull($location->lng),
            'heading' => $location->heading,
            'speed' => $location->speed,
            'accuracy' => $location->accuracy,
            'is_tracking' => $location->isTracking,
            'updated_at' => $location->updatedAt?->format(DATE_ATOM),
        ];
    }
}
