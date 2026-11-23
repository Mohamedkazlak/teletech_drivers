<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\DriverRecommendation;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin DriverRecommendation
 */
final class DriverRecommendationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var DriverRecommendation $item */
        $item = $this->resource;

        return [
            'driver' => (new DriverSummaryResource($item->driver))->resolve(),
            'tier' => $item->tier,
            'has_favorite_match' => $item->hasFavoriteMatch,
            'has_conflict' => $item->hasConflict,
            'is_on_active_trip' => $item->isOnActiveTrip,
            'is_unavailable' => $item->isUnavailable,
            'needs_confirmation' => $item->needsConfirmation,
            'trips_this_week' => $item->tripsThisWeek,
        ];
    }
}
