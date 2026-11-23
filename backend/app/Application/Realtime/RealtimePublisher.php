<?php

declare(strict_types=1);

namespace App\Application\Realtime;

use App\Domain\Entities\DriverLocation;
use App\Domain\Entities\Trip;
use App\Domain\Entities\TripRequest;
use App\Events\DriverLocationBroadcast;
use App\Models\AttendanceLog;
use App\Events\FleetBroadcast;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Support\Facades\DB;
use Throwable;

/**
 * Dispatches minimal broadcast events after a successful write.
 * A down socket server must not fail the API call.
 */
final class RealtimePublisher
{
    public function tripRequest(string $eventName, TripRequest $request): void
    {
        $this->send(new FleetBroadcast(
            eventName: $eventName,
            id: $request->id,
            status: $request->status->value,
            userIds: [$request->employeeId],
        ));
    }

    public function trip(string $eventName, Trip $trip, ?string $status = null): void
    {
        $userIds = [];
        if ($trip->driverId !== null) {
            $userIds[] = $trip->driverId;
        }
        foreach ($trip->passengers as $passenger) {
            $userIds[] = $passenger->employeeId;
        }

        $this->send(new FleetBroadcast(
            eventName: $eventName,
            id: $trip->id,
            status: $status ?? $trip->status->value,
            userIds: $userIds,
        ));
    }

    public function attendance(string $eventName, AttendanceLog $log): void
    {
        $this->send(new FleetBroadcast(
            eventName: $eventName,
            id: (string) $log->id,
            status: $log->status(),
            userIds: [(string) $log->driver_id],
            audience: 'attendance',
        ));
    }

    public function location(DriverLocation $location, string $status): void
    {
        $this->send(new DriverLocationBroadcast(
            driverId: $location->driverId,
            tripId: $location->tripId,
            lat: $location->lat,
            lng: $location->lng,
            status: $status,
        ));
    }

    private function send(ShouldBroadcast $event): void
    {
        // A transaction defers ShouldBroadcast until commit, outside this
        // try/catch, so a down socket server fails the request. Broadcast now
        // and put the flag back so callers still see afterCommit.
        $restoreAfterCommit = false;
        if (DB::transactionLevel() > 0 && property_exists($event, 'afterCommit') && $event->afterCommit === true) {
            $event->afterCommit = false;
            $restoreAfterCommit = true;
        }

        try {
            $this->broadcastNow($event);
        } finally {
            if ($restoreAfterCommit) {
                $event->afterCommit = true;
            }
        }
    }

    private function broadcastNow(ShouldBroadcast $event): void
    {
        try {
            event($event);
        } catch (Throwable $exception) {
            report($exception);
        }
    }
}
