<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent\Support;

use App\Domain\Entities\RequestTracking;
use App\Domain\Enums\TripStatus;
use App\Domain\Services\TripRequest\RequestTrackingFacts;
use App\Domain\Services\TripRequest\RequestTrackingService;
use App\Models\Trip as TripModel;
use App\Models\TripRequest as TripRequestModel;
use DateTimeImmutable;
use DateTimeInterface;

/**
 * Assembles {@see RequestTrackingFacts} from stored rows and delegates
 * the stage to {@see RequestTrackingService}.
 */
final class RequestTrackingFactory
{
    public function __construct(
        private readonly RequestTrackingService $tracking,
    ) {}

    public function fromRequest(TripRequestModel $request): RequestTracking
    {
        $request->loadMissing(['trip.driver.driverProfile', 'trip.confirmedBy']);

        return $this->tracking->build($this->facts($request, $request->trip));
    }

    public function fromTripForEmployee(TripModel $trip, string $employeeId): ?RequestTracking
    {
        if (! $trip->relationLoaded('tripRequests')) {
            return null;
        }

        $match = null;
        foreach ($trip->tripRequests as $request) {
            if ((string) $request->employee_id !== $employeeId) {
                continue;
            }
            if ($match === null || $request->created_at > $match->created_at) {
                $match = $request;
            }
        }

        if ($match === null) {
            return null;
        }

        $trip->loadMissing(['driver.driverProfile', 'confirmedBy']);

        return $this->tracking->build($this->facts($match, $trip));
    }

    private function facts(TripRequestModel $request, ?TripModel $trip): RequestTrackingFacts
    {
        $driver = $trip !== null && $trip->relationLoaded('driver') ? $trip->driver : null;
        $profile = $driver !== null && $driver->relationLoaded('driverProfile')
            ? $driver->driverProfile
            : null;
        $confirmer = $trip !== null && $trip->relationLoaded('confirmedBy') ? $trip->confirmedBy : null;
        $hasDriver = $trip !== null
            && $trip->driver_id !== null
            && $trip->status !== TripStatus::Unassigned;

        return new RequestTrackingFacts(
            requestStatus: $request->status,
            requesterRole: $request->requester_role,
            autoApproved: (bool) $request->auto_approved,
            createdAt: self::immutable($request->created_at),
            approvedAt: self::immutableOrNull($request->approved_at),
            handledAt: self::immutableOrNull($request->handled_at),
            rejectionReason: $request->rejection_reason,
            requestUpdatedAt: self::immutableOrNull($request->updated_at),
            tripStatus: $trip?->status,
            scheduledAt: $trip !== null ? self::immutableOrNull($trip->scheduled_at) : null,
            assignedAt: self::immutableOrNull($trip?->assigned_at),
            goingStartedAt: self::immutableOrNull($trip?->going_started_at),
            finishedAt: self::immutableOrNull($trip?->finished_at),
            confirmationStatus: $trip?->confirmation_status,
            confirmationRequestedAt: self::immutableOrNull($trip?->confirmation_requested_at),
            confirmedAt: self::immutableOrNull($trip?->confirmed_at),
            confirmationActorRole: $confirmer?->role,
            tripUpdatedAt: self::immutableOrNull($trip?->updated_at),
            hasDriver: $hasDriver,
            driverNameEn: $hasDriver ? $driver?->name_en : null,
            driverNameAr: $hasDriver ? $driver?->name_ar : null,
            driverPhone: $hasDriver ? $driver?->phone : null,
            carLicense: $hasDriver ? $profile?->car_license : null,
        );
    }

    private static function immutableOrNull(mixed $value): ?DateTimeImmutable
    {
        if ($value === null) {
            return null;
        }

        return self::immutable($value);
    }

    private static function immutable(mixed $value): DateTimeImmutable
    {
        if ($value instanceof DateTimeImmutable) {
            return $value;
        }

        if ($value instanceof DateTimeInterface) {
            return DateTimeImmutable::createFromInterface($value);
        }

        return new DateTimeImmutable((string) $value);
    }
}
