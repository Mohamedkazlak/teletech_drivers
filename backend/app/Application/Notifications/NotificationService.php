<?php

declare(strict_types=1);

namespace App\Application\Notifications;

use App\Domain\Entities\Trip;
use App\Domain\Entities\TripRequest;
use App\Domain\Enums\NotificationType;
use App\Domain\Enums\UserRole;
use App\Domain\Repositories\NotificationRepositoryInterface;
use App\Domain\Repositories\TripRequestRepositoryInterface;
use App\Domain\Repositories\UserRepositoryInterface;
use App\Jobs\SendPushNotification;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * One method per lifecycle event. Callers invoke it inside the same
 * database transaction as the state change. The actor is skipped, except
 * own_trip_assigned: the company or drivers admin who owns the trip still
 * receives it when they are the one who picks the driver.
 */
final class NotificationService
{
    public function __construct(
        private readonly NotificationRepositoryInterface $notifications,
        private readonly UserRepositoryInterface $users,
        private readonly TripRequestRepositoryInterface $tripRequests,
    ) {}

    public function requestSubmitted(TripRequest $request, string $actorId): void
    {
        $this->fanOut(
            role: UserRole::CompanyAdmin,
            actorId: $actorId,
            type: NotificationType::RequestSubmitted,
            tripRequestId: $request->id,
            tripId: $request->tripId,
            params: $this->params($request),
        );
    }

    public function tripReadyToAssign(TripRequest $request, string $actorId): void
    {
        $this->fanOut(
            role: UserRole::DriversAdmin,
            actorId: $actorId,
            type: NotificationType::TripReadyToAssign,
            tripRequestId: $request->id,
            tripId: $request->tripId,
            params: $this->params($request),
        );
    }

    public function driverAssigned(Trip $trip, string $actorId): void
    {
        $requests = $this->tripRequests->listByTripId($trip->id);
        $driver = $trip->driver?->user;
        if ($driver === null && $trip->driverId !== null) {
            $driver = $this->users->findById($trip->driverId);
        }

        $driverNameEn = $driver?->nameEn;
        $driverNameAr = $driver?->nameAr;
        $onlyRequestId = count($requests) === 1 ? $requests[0]->id : null;

        if ($trip->driverId !== null) {
            $this->store(
                userId: $trip->driverId,
                actorId: $actorId,
                type: NotificationType::TripAssigned,
                notifyActor: false,
                tripRequestId: $onlyRequestId,
                tripId: $trip->id,
                params: $this->tripParams(
                    pickup: (string) ($trip->pickupSummary ?? ''),
                    destination: (string) ($trip->destinationSummary ?? ''),
                    driverNameEn: $driverNameEn,
                    driverNameAr: $driverNameAr,
                ),
            );
        }

        foreach ($requests as $request) {
            $ownTrip = $request->requesterRole === UserRole::CompanyAdmin
                || $request->requesterRole === UserRole::DriversAdmin;

            $this->store(
                userId: $request->employeeId,
                actorId: $actorId,
                type: $ownTrip ? NotificationType::OwnTripAssigned : NotificationType::TripAssigned,
                notifyActor: $ownTrip,
                tripRequestId: $request->id,
                tripId: $trip->id,
                params: $this->params($request, $driverNameEn, $driverNameAr),
            );
        }
    }

    public function tripEnded(string $tripId, string $actorId): void
    {
        foreach ($this->tripRequests->listByTripId($tripId) as $request) {
            $this->store(
                userId: $request->employeeId,
                actorId: $actorId,
                type: NotificationType::TripEndedReportNeeded,
                notifyActor: false,
                tripRequestId: $request->id,
                tripId: $tripId,
                params: $this->params($request),
            );
        }
    }

    /**
     * @param  array<string, mixed>  $params
     */
    private function fanOut(
        UserRole $role,
        string $actorId,
        NotificationType $type,
        ?string $tripRequestId,
        ?string $tripId,
        array $params,
    ): void {
        foreach ($this->users->activeIdsForRole($role) as $userId) {
            $this->store(
                userId: $userId,
                actorId: $actorId,
                type: $type,
                notifyActor: false,
                tripRequestId: $tripRequestId,
                tripId: $tripId,
                params: $params,
            );
        }
    }

    /**
     * @param  array<string, mixed>  $params
     */
    private function store(
        string $userId,
        string $actorId,
        NotificationType $type,
        bool $notifyActor,
        ?string $tripRequestId,
        ?string $tripId,
        array $params,
    ): void {
        if ($userId === '' || (! $notifyActor && $userId === $actorId)) {
            return;
        }

        $notification = $this->notifications->create(
            userId: $userId,
            type: $type,
            titleKey: $type->titleKey(),
            bodyKey: $type->bodyKey(),
            params: $params,
            tripRequestId: $tripRequestId,
            tripId: $tripId,
        );

        $this->queuePush($notification->id);
    }

    private function queuePush(string $notificationId): void
    {
        try {
            SendPushNotification::dispatch($notificationId)->afterCommit();
        } catch (Throwable $exception) {
            Log::error('Push notification was not queued.', [
                'notification_id' => $notificationId,
                'error' => $exception->getMessage(),
            ]);
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function params(
        TripRequest $request,
        ?string $driverNameEn = null,
        ?string $driverNameAr = null,
    ): array {
        return $this->tripParams(
            pickup: $request->pickup->name,
            destination: $request->destination->name,
            requesterNameEn: $request->employeeNameEn,
            requesterNameAr: $request->employeeNameAr,
            driverNameEn: $driverNameEn,
            driverNameAr: $driverNameAr,
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function tripParams(
        string $pickup,
        string $destination,
        ?string $requesterNameEn = null,
        ?string $requesterNameAr = null,
        ?string $driverNameEn = null,
        ?string $driverNameAr = null,
    ): array {
        return [
            'requester_name_en' => $requesterNameEn ?? '',
            'requester_name_ar' => $requesterNameAr ?? '',
            'driver_name_en' => $driverNameEn ?? '',
            'driver_name_ar' => $driverNameAr ?? '',
            'pickup' => $pickup,
            'destination' => $destination,
        ];
    }
}
