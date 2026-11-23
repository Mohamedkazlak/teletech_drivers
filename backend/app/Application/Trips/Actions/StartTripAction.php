<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Realtime\RealtimePublisher;
use App\Application\Trips\DTOs\StartTripData;
use App\Domain\Entities\Trip;
use App\Domain\Exceptions\TripNotFoundException;
use App\Domain\Repositories\TripRepositoryInterface;

final class StartTripAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(StartTripData $data): Trip
    {
        $trip = $this->trips->findById($data->tripId);
        if ($trip === null) {
            throw new TripNotFoundException;
        }

        // Ownership is enforced by TripPolicy::drive; action only performs transition.
        $trip = $this->trips->startTrip($data->tripId, $data->startLat, $data->startLng);
        $this->realtime->trip('trip.started', $trip);

        return $trip;
    }
}
