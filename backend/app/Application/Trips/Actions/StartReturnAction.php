<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Realtime\RealtimePublisher;
use App\Domain\Entities\Trip;
use App\Domain\Exceptions\TripNotFoundException;
use App\Domain\Repositories\TripRepositoryInterface;

final class StartReturnAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(string $tripId): Trip
    {
        if ($this->trips->findById($tripId) === null) {
            throw new TripNotFoundException;
        }

        $trip = $this->trips->startReturn($tripId);
        $this->realtime->trip('trip.phase-changed', $trip);

        return $trip;
    }
}
