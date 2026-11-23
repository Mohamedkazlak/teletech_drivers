<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent\Mappers;

use App\Domain\Entities\GroupableTripRequest;
use App\Domain\Entities\LinkedTrip;
use App\Domain\Entities\PlaceSnapshot;
use App\Domain\Entities\TripRequest as TripRequestEntity;
use App\Infrastructure\Persistence\Eloquent\Support\RequestTrackingFactory;
use App\Models\TripRequest as TripRequestModel;
use DateTimeImmutable;

final class TripRequestMapper
{
    public static function toDomain(TripRequestModel $model): TripRequestEntity
    {
        $employee = $model->relationLoaded('employee') ? $model->employee : null;
        $linkedTrip = null;
        if ($model->relationLoaded('trip') && $model->trip !== null) {
            $driver = $model->trip->relationLoaded('driver') ? $model->trip->driver : null;
            $linkedTrip = new LinkedTrip(
                id: (string) $model->trip->id,
                status: $model->trip->status,
                driverNameEn: $driver?->name_en,
                driverNameAr: $driver?->name_ar,
                confirmationStatus: $model->trip->confirmation_status,
                driverShowedUp: $model->trip->driver_showed_up,
            );
        }

        return new TripRequestEntity(
            id: (string) $model->id,
            employeeId: (string) $model->employee_id,
            requesterRole: $model->requester_role,
            pickup: new PlaceSnapshot(
                placeId: $model->pickup_place_id !== null ? (string) $model->pickup_place_id : null,
                name: $model->pickup_name,
                lat: $model->pickup_lat !== null ? (float) $model->pickup_lat : null,
                lng: $model->pickup_lng !== null ? (float) $model->pickup_lng : null,
                address: $model->pickup_address,
            ),
            destination: new PlaceSnapshot(
                placeId: $model->destination_place_id !== null ? (string) $model->destination_place_id : null,
                name: $model->destination_name,
                lat: $model->destination_lat !== null ? (float) $model->destination_lat : null,
                lng: $model->destination_lng !== null ? (float) $model->destination_lng : null,
                address: $model->destination_address,
            ),
            requestedAt: DateTimeImmutable::createFromMutable($model->requested_at),
            notes: (string) $model->notes,
            status: $model->status,
            tripId: $model->trip_id !== null ? (string) $model->trip_id : null,
            rejectionReason: $model->rejection_reason,
            handledBy: $model->handled_by !== null ? (string) $model->handled_by : null,
            handledAt: $model->handled_at !== null
                ? DateTimeImmutable::createFromMutable($model->handled_at)
                : null,
            autoApproved: (bool) $model->auto_approved,
            suggestedGroupId: $model->suggested_group_id !== null ? (string) $model->suggested_group_id : null,
            createdAt: DateTimeImmutable::createFromMutable($model->created_at),
            employeeNameEn: $employee?->name_en,
            employeeNameAr: $employee?->name_ar,
            employeePhone: $employee?->phone,
            employeeBranch: $employee?->branch?->value,
            tripStatus: $model->relationLoaded('trip') ? $model->trip?->status : null,
            linkedTrip: $linkedTrip,
            approvedAt: $model->approved_at !== null
                ? DateTimeImmutable::createFromInterface($model->approved_at)
                : null,
            tracking: app(RequestTrackingFactory::class)->fromRequest($model),
        );
    }

    public static function toGroupable(TripRequestModel $model): GroupableTripRequest
    {
        $employee = $model->relationLoaded('employee') ? $model->employee : null;

        return new GroupableTripRequest(
            id: (string) $model->id,
            requestedAt: DateTimeImmutable::createFromMutable($model->requested_at),
            destinationPlaceId: $model->destination_place_id !== null ? (string) $model->destination_place_id : null,
            destinationLat: $model->destination_lat !== null ? (float) $model->destination_lat : null,
            destinationLng: $model->destination_lng !== null ? (float) $model->destination_lng : null,
            destinationName: $model->destination_name,
            pickupName: $model->pickup_name,
            requesterNameEn: $employee?->name_en,
            requesterNameAr: $employee?->name_ar,
            branch: $employee?->branch?->value,
        );
    }
}
