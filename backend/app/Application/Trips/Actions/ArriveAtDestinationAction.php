<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Realtime\RealtimePublisher;
use App\Application\Trips\DTOs\ArriveAtDestinationData;
use App\Domain\Entities\Trip;
use App\Domain\Exceptions\TripNotFoundException;
use App\Domain\Repositories\TripRepositoryInterface;

final class ArriveAtDestinationAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(ArriveAtDestinationData $data): Trip
    {
        if ($this->trips->findById($data->tripId) === null) {
            throw new TripNotFoundException;
        }

        $trip = $this->trips->arriveAtDestination(
            $data->tripId,
            $data->goingDistanceM,
            $data->goingRoute,
        );
        $this->realtime->trip('trip.phase-changed', $trip);

        return $trip;
    }
}
