<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Notifications\NotificationService;
use App\Application\Realtime\RealtimePublisher;
use App\Application\Trips\DTOs\EndTripData;
use App\Domain\Entities\Trip;
use App\Domain\Exceptions\TripNotFoundException;
use App\Domain\Repositories\TripRepositoryInterface;
use Illuminate\Support\Facades\DB;

final class EndTripAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
        private readonly NotificationService $notifications,
    ) {}

    public function execute(EndTripData $data): Trip
    {
        $trip = DB::transaction(function () use ($data): Trip {
            if ($this->trips->findById($data->tripId) === null) {
                throw new TripNotFoundException;
            }

            $trip = $this->trips->endTrip(
                $data->tripId,
                $data->returnDistanceM,
                $data->returnRoute,
            );
            $this->notifications->tripEnded($data->tripId, $data->actorId);

            return $trip;
        });
        $this->realtime->trip('trip.ended', $trip);

        return $trip;
    }
}
