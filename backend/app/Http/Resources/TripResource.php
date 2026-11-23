<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\Trip;
use App\Http\Support\JsonNumber;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Full trip including routes and start coordinates.
 *
 * @mixin Trip
 */
final class TripResource extends JsonResource
{
    public function __construct(
        mixed $resource,
        private readonly ?string $viewerId = null,
        private readonly bool $limitToViewer = false,
    ) {
        parent::__construct($resource);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var Trip $trip */
        $trip = $this->resource;
        $summary = (new TripSummaryResource($trip, $this->viewerId, $this->limitToViewer))
            ->toArray($request);

        return [
            ...$summary,
            'start_lat' => JsonNumber::orNull($trip->startLat),
            'start_lng' => JsonNumber::orNull($trip->startLng),
            'going_route' => $trip->goingRoute,
            'return_route' => $trip->returnRoute,
        ];
    }
}
