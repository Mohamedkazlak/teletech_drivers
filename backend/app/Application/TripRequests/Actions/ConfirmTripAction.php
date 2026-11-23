<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Actions;

use App\Application\Realtime\RealtimePublisher;
use App\Application\TripRequests\DTOs\ConfirmTripData;
use App\Domain\Entities\TripRequest;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Repositories\TripRequestRepositoryInterface;

final class ConfirmTripAction
{
    public function __construct(
        private readonly TripRequestRepositoryInterface $tripRequests,
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(ConfirmTripData $data): TripRequest
    {
        $request = $this->tripRequests->confirmTrip(
            requestId: $data->requestId,
            actorId: $data->actorId,
            driverShowedUp: $data->driverShowedUp,
            note: $data->note,
        );
        if ($request->tripId !== null) {
            $trip = $this->trips->findById($request->tripId);
            if ($trip !== null) {
                $this->realtime->trip(
                    'trip.confirmed',
                    $trip,
                    $trip->confirmationStatus?->value ?? 'confirmed',
                );
            }
        }

        return $request;
    }
}
