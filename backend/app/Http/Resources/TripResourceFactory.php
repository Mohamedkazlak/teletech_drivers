<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\Trip;
use App\Models\Trip as TripModel;
use App\Models\User;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Chooses full vs summary trip resource via TripPolicy::viewSensitiveFields.
 */
final class TripResourceFactory
{
    public static function make(
        User $actor,
        Trip $trip,
        TripModel $model,
        bool $limitToViewer = false,
    ): JsonResource {
        $viewerId = (string) $actor->id;
        if ($actor->can('viewSensitiveFields', $model)) {
            return new TripResource($trip, $viewerId, $limitToViewer);
        }

        return new TripSummaryResource($trip, $viewerId, $limitToViewer);
    }
}
