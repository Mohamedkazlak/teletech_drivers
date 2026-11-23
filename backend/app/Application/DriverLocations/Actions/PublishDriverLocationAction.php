<?php

declare(strict_types=1);

namespace App\Application\DriverLocations\Actions;

use App\Application\DriverLocations\DTOs\PublishDriverLocationData;
use App\Application\Realtime\RealtimePublisher;
use App\Domain\Entities\DriverLocation;
use App\Domain\Exceptions\InvalidDriverLocationTripException;
use App\Domain\Exceptions\LocationAccuracyExceededException;
use App\Domain\Exceptions\TripNotFoundException;
use App\Domain\Repositories\DriverLocationRepositoryInterface;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Specifications\InProgressTripSpecification;

final class PublishDriverLocationAction
{
    public function __construct(
        private readonly DriverLocationRepositoryInterface $locations,
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
        private readonly InProgressTripSpecification $inProgress = new InProgressTripSpecification,
    ) {}

    public function execute(PublishDriverLocationData $data): DriverLocation
    {
        $existing = $this->locations->findByDriverId($data->driverId);
        $maxAccuracy = $existing === null
            ? (float) config('teletech.location_first_publish_accuracy_max_meters', 500)
            : (float) config('teletech.location_accuracy_max_meters', 50);

        if ($data->accuracy > $maxAccuracy) {
            throw new LocationAccuracyExceededException($data->accuracy, $maxAccuracy);
        }

        if ($data->tripId !== null) {
            $trip = $this->trips->findById($data->tripId);
            if ($trip === null) {
                throw new TripNotFoundException;
            }
            if ($trip->driverId !== $data->driverId || ! $this->inProgress->isSatisfiedBy($trip->status)) {
                throw new InvalidDriverLocationTripException;
            }
        }

        $location = $this->locations->upsert(
            driverId: $data->driverId,
            tripId: $data->tripId,
            lat: $data->lat,
            lng: $data->lng,
            heading: $data->heading,
            speed: $data->speed,
            accuracy: $data->accuracy,
            isTracking: $data->isTracking,
        );
        $this->realtime->location($location, $location->isTracking ? 'tracking' : 'stopped');

        return $location;
    }
}
