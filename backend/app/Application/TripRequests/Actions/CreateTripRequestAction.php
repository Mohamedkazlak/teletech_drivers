<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Actions;

use App\Application\Notifications\NotificationService;
use App\Application\Realtime\RealtimePublisher;
use App\Application\TripRequests\DTOs\CreateTripRequestData;
use App\Application\TripRequests\Services\PlaceSnapshotResolver;
use App\Application\TripRequests\Services\TripRequestCreateValidator;
use App\Domain\Entities\TripRequest;
use App\Domain\Enums\UserRole;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Repositories\TripRequestRepositoryInterface;
use App\Domain\Services\TripRequest\CreateTripRequestStrategyFactory;
use DateTimeImmutable;
use Illuminate\Support\Facades\DB;

final class CreateTripRequestAction
{
    public function __construct(
        private readonly TripRequestRepositoryInterface $tripRequests,
        private readonly CreateTripRequestStrategyFactory $strategyFactory,
        private readonly PlaceSnapshotResolver $placeResolver,
        private readonly TripRequestCreateValidator $validator,
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
        private readonly NotificationService $notifications,
    ) {}

    public function execute(CreateTripRequestData $data): TripRequest
    {
        $request = DB::transaction(function () use ($data): TripRequest {
            $pickup = $this->placeResolver->resolve($data->pickup);
            $destination = $this->placeResolver->resolve($data->destination);
            $now = new DateTimeImmutable('now');
            $this->validator->assertValid($pickup, $destination, $data->requestedAt);

            $plan = $this->strategyFactory->forRole($data->actorRole)->build();

            $handledBy = $plan->setHandledBy ? $data->actorId : null;
            $handledAt = $plan->setHandledBy ? $now : null;

            $request = $plan->createTrip
                ? $this->tripRequests->createWithUnassignedTrip(
                    employeeId: $data->actorId,
                    requesterRole: $plan->requesterRole,
                    pickup: $pickup,
                    destination: $destination,
                    requestedAt: $data->requestedAt,
                    notes: $data->notes,
                    status: $plan->status,
                    autoApproved: $plan->autoApproved,
                    handledBy: (string) $handledBy,
                    handledAt: $handledAt ?? $now,
                    createdBy: $data->actorId,
                )
                : $this->tripRequests->create(
                    employeeId: $data->actorId,
                    requesterRole: $plan->requesterRole,
                    pickup: $pickup,
                    destination: $destination,
                    requestedAt: $data->requestedAt,
                    notes: $data->notes,
                    status: $plan->status,
                    autoApproved: $plan->autoApproved,
                    handledBy: $handledBy,
                    handledAt: $handledAt,
                );

            $this->notifyForNewRequest($data, $request);

            return $request;
        });

        $this->realtime->tripRequest('trip-request.created', $request);
        if ($request->tripId !== null) {
            $trip = $this->trips->findById($request->tripId);
            if ($trip !== null) {
                $this->realtime->trip('trip.created', $trip);
            }
        }

        return $request;
    }

    private function notifyForNewRequest(CreateTripRequestData $data, TripRequest $request): void
    {
        if ($data->actorRole === UserRole::Employee) {
            $this->notifications->requestSubmitted($request, $data->actorId);

            return;
        }

        if ($data->actorRole === UserRole::CompanyAdmin) {
            $this->notifications->tripReadyToAssign($request, $data->actorId);
        }
    }
}
