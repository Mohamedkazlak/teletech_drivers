<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Realtime\RealtimePublisher;
use App\Domain\Entities\Trip;
use App\Domain\Repositories\TripRepositoryInterface;

final class CancelTripAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(string $tripId): Trip
    {
        $trip = $this->trips->cancel($tripId);
        $this->realtime->trip('trip.cancelled', $trip);

        return $trip;
    }
}
