<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Realtime\RealtimePublisher;
use App\Application\Trips\DTOs\CreateTripsFromRequestsData;
use App\Domain\Entities\Trip;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Services\ScheduleTime;
use Illuminate\Validation\ValidationException;

final class CreateTripsFromRequestsAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
        private readonly ScheduleTime $schedule,
    ) {}

    /**
     * @return list<Trip>
     */
    public function execute(CreateTripsFromRequestsData $data): array
    {
        if ($data->scheduledAt !== null && $this->schedule->isNotFuture($data->scheduledAt)) {
            throw ValidationException::withMessages([
                'scheduled_at' => [__('messages.scheduled_in_past')],
            ]);
        }

        $created = $this->trips->createFromRequests(
            requestIds: array_values(array_unique($data->requestIds)),
            mode: $data->mode,
            scheduledAt: $data->scheduledAt,
            createdBy: $data->createdBy,
        );
        foreach ($created as $trip) {
            $this->realtime->trip('trip.created', $trip);
        }

        return $created;
    }
}
