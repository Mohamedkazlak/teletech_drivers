<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent\Mappers;

use App\Domain\Entities\Driver as DriverEntity;
use App\Domain\Entities\PlaceSnapshot;
use App\Domain\Entities\RequestTracking;
use App\Domain\Entities\Trip as TripEntity;
use App\Domain\Entities\TripPassenger;
use App\Infrastructure\Persistence\Eloquent\Support\RequestTrackingFactory;
use App\Models\Trip as TripModel;
use App\Models\TripRequest as TripRequestModel;
use DateTimeImmutable;

final class TripMapper
{
    public static function toDomain(TripModel $model): TripEntity
    {
        $passengers = [];
        if ($model->relationLoaded('tripRequests')) {
            foreach ($model->tripRequests as $request) {
                /** @var TripRequestModel $request */
                $employee = $request->relationLoaded('employee') ? $request->employee : null;
                $passengers[] = new TripPassenger(
                    employeeId: (string) $request->employee_id,
                    nameEn: $employee?->name_en ?? '',
                    nameAr: $employee?->name_ar,
                    phone: $employee?->phone,
                    branch: $employee?->branch?->value,
                    requestId: (string) $request->id,
                    pickup: new PlaceSnapshot(
                        placeId: $request->pickup_place_id !== null ? (string) $request->pickup_place_id : null,
                        name: $request->pickup_name,
                        lat: $request->pickup_lat !== null ? (float) $request->pickup_lat : null,
                        lng: $request->pickup_lng !== null ? (float) $request->pickup_lng : null,
                        address: $request->pickup_address,
                    ),
                    destination: new PlaceSnapshot(
                        placeId: $request->destination_place_id !== null ? (string) $request->destination_place_id : null,
                        name: $request->destination_name,
                        lat: $request->destination_lat !== null ? (float) $request->destination_lat : null,
                        lng: $request->destination_lng !== null ? (float) $request->destination_lng : null,
                        address: $request->destination_address,
                    ),
                );
            }
        }

        $driver = null;
        if ($model->relationLoaded('driver') && $model->driver !== null) {
            $driverUser = $model->driver;
            $profile = $driverUser->relationLoaded('driverProfile') ? $driverUser->driverProfile : null;
            $favoriteIds = $driverUser->relationLoaded('favoritePlaces')
                ? $driverUser->favoritePlaces->pluck('id')->map(static fn ($id): string => (string) $id)->all()
                : [];

            $driver = new DriverEntity(
                user: UserMapper::toDomain($driverUser),
                nationalId: $profile?->national_id ?? '',
                carLicense: $profile?->car_license ?? '',
                personalLicense: $profile?->personal_license ?? '',
                favoritePlaceIds: $favoriteIds,
            );
        }

        $trackingByEmployeeId = [];
        if ($model->relationLoaded('tripRequests')) {
            $factory = app(RequestTrackingFactory::class);
            foreach ($model->tripRequests as $request) {
                $employeeId = (string) $request->employee_id;
                $trackingByEmployeeId[$employeeId] = $factory->fromTripForEmployee($model, $employeeId);
            }
            $trackingByEmployeeId = array_filter(
                $trackingByEmployeeId,
                static fn (?RequestTracking $tracking): bool => $tracking !== null,
            );
        }

        return new TripEntity(
            id: (string) $model->id,
            driverId: $model->driver_id !== null ? (string) $model->driver_id : null,
            scheduledAt: DateTimeImmutable::createFromMutable($model->scheduled_at),
            status: $model->status,
            createdBy: (string) $model->created_by,
            pickupSummary: $model->pickup_summary,
            destinationSummary: $model->destination_summary,
            goingStartedAt: $model->going_started_at !== null
                ? DateTimeImmutable::createFromMutable($model->going_started_at)
                : null,
            goingEndedAt: $model->going_ended_at !== null
                ? DateTimeImmutable::createFromMutable($model->going_ended_at)
                : null,
            returnStartedAt: $model->return_started_at !== null
                ? DateTimeImmutable::createFromMutable($model->return_started_at)
                : null,
            finishedAt: $model->finished_at !== null
                ? DateTimeImmutable::createFromMutable($model->finished_at)
                : null,
            startLat: $model->start_lat !== null ? (float) $model->start_lat : null,
            startLng: $model->start_lng !== null ? (float) $model->start_lng : null,
            goingDistanceM: $model->going_distance_m !== null ? (int) $model->going_distance_m : null,
            returnDistanceM: $model->return_distance_m !== null ? (int) $model->return_distance_m : null,
            totalDistanceM: $model->total_distance_m !== null ? (int) $model->total_distance_m : null,
            goingRoute: $model->going_route,
            returnRoute: $model->return_route,
            createdAt: DateTimeImmutable::createFromMutable($model->created_at),
            passengers: $passengers,
            driver: $driver,
            confirmationStatus: $model->confirmation_status,
            confirmationRequestedAt: $model->confirmation_requested_at !== null
                ? DateTimeImmutable::createFromMutable($model->confirmation_requested_at)
                : null,
            confirmedAt: $model->confirmed_at !== null
                ? DateTimeImmutable::createFromMutable($model->confirmed_at)
                : null,
            confirmedBy: $model->confirmed_by !== null ? (string) $model->confirmed_by : null,
            driverShowedUp: $model->driver_showed_up,
            confirmationNote: $model->confirmation_note,
            assignedAt: $model->assigned_at !== null
                ? DateTimeImmutable::createFromInterface($model->assigned_at)
                : null,
            trackingByEmployeeId: $trackingByEmployeeId,
        );
    }
}
