<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Notifications\NotificationService;
use App\Application\Realtime\RealtimePublisher;
use App\Application\Trips\DTOs\AssignDriverData;
use App\Domain\Entities\Trip;
use App\Domain\Exceptions\InvalidDriverForAssignmentException;
use App\Domain\Repositories\TripRepositoryInterface;
use Illuminate\Support\Facades\DB;

final class AssignDriverAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
        private readonly NotificationService $notifications,
    ) {}

    public function execute(AssignDriverData $data): Trip
    {
        $trip = DB::transaction(function () use ($data): Trip {
            if (! $this->trips->isAssignableDriver($data->driverId)) {
                throw new InvalidDriverForAssignmentException;
            }

            $trip = $this->trips->assignDriver($data->tripId, $data->driverId);
            $this->notifications->driverAssigned($trip, $data->actorId);

            return $trip;
        });
        $this->realtime->trip('trip.assigned', $trip);

        return $trip;
    }
}
