<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Services;

use App\Application\TripRequests\DTOs\PlaceInputData;
use App\Domain\Entities\PlaceSnapshot;
use App\Domain\Exceptions\PlaceMissingCoordinatesException;
use App\Domain\Exceptions\PlaceNotFoundException;
use App\Domain\Repositories\PlaceRepositoryInterface;

final class PlaceSnapshotResolver
{
    public function __construct(
        private readonly PlaceRepositoryInterface $places,
    ) {}

    public function resolve(PlaceInputData $input): PlaceSnapshot
    {
        if ($input->isPlaceId()) {
            $place = $this->places->findById((string) $input->placeId);
            if ($place === null || ! $place->isActive) {
                throw new PlaceNotFoundException;
            }
            if ($place->latitude === null || $place->longitude === null) {
                throw new PlaceMissingCoordinatesException;
            }

            return new PlaceSnapshot(
                placeId: $place->id,
                name: $place->nameEn,
                lat: $place->latitude,
                lng: $place->longitude,
                address: $place->address,
            );
        }

        return new PlaceSnapshot(
            placeId: null,
            name: (string) $input->name,
            lat: $input->lat,
            lng: $input->lng,
            address: $input->address,
        );
    }
}
