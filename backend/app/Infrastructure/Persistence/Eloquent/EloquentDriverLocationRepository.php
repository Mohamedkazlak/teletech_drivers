<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Entities\DriverLocation as DriverLocationEntity;
use App\Domain\Entities\LiveMapDriver;
use App\Domain\Enums\DriverAttendanceFilter;
use App\Domain\Enums\LiveMapState;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\DriverLocationNotFoundException;
use App\Domain\Repositories\DriverLocationRepositoryInterface;
use App\Infrastructure\Persistence\Eloquent\Mappers\DriverLocationMapper;
use App\Infrastructure\Persistence\Eloquent\Mappers\DriverMapper;
use App\Infrastructure\Persistence\Eloquent\Mappers\TripMapper;
use App\Models\DriverLocation as DriverLocationModel;
use App\Models\Trip as TripModel;
use App\Models\User;
use DateTimeImmutable;
use Illuminate\Support\Facades\DB;

final class EloquentDriverLocationRepository implements DriverLocationRepositoryInterface
{
    public function findByDriverId(string $driverId): ?DriverLocationEntity
    {
        $model = DriverLocationModel::query()->find($driverId);

        return $model === null ? null : DriverLocationMapper::toDomain($model);
    }

    public function upsert(
        string $driverId,
        ?string $tripId,
        float $lat,
        float $lng,
        float $heading,
        float $speed,
        float $accuracy,
        bool $isTracking,
    ): DriverLocationEntity {
        return DB::transaction(function () use (
            $driverId,
            $tripId,
            $lat,
            $lng,
            $heading,
            $speed,
            $accuracy,
            $isTracking,
        ): DriverLocationEntity {
            $model = DriverLocationModel::query()->whereKey($driverId)->lockForUpdate()->first();
            $now = now();

            if ($model === null) {
                $model = new DriverLocationModel;
                $model->driver_id = $driverId;
            }

            $model->trip_id = $tripId;
            $model->lat = $lat;
            $model->lng = $lng;
            $model->heading = $heading;
            $model->speed = $speed;
            $model->accuracy = $accuracy;
            $model->is_tracking = $isTracking;
            $model->updated_at = $now;
            $model->save();

            return DriverLocationMapper::toDomain($model->fresh());
        });
    }

    public function stopTracking(string $driverId): DriverLocationEntity
    {
        return DB::transaction(function () use ($driverId): DriverLocationEntity {
            $model = DriverLocationModel::query()->whereKey($driverId)->lockForUpdate()->first();
            if ($model === null) {
                throw new DriverLocationNotFoundException;
            }

            $model->is_tracking = false;
            $model->updated_at = now();
            $model->save();

            return DriverLocationMapper::toDomain($model);
        });
    }

    public function listLiveMap(?string $driverId = null, ?DriverAttendanceFilter $attendance = null): array
    {
        $staleSeconds = (int) config('teletech.location_stale_seconds', 60);
        $nowTs = (new DateTimeImmutable('now'))->getTimestamp();

        $drivers = User::query()
            ->with(['driverProfile', 'favoritePlaces', 'todayAttendance', 'activeTrip'])
            ->where('role', UserRole::Driver)
            ->where('is_active', true)
            ->when(
                $driverId !== null && $driverId !== '',
                fn ($query) => $query->whereKey($driverId),
            )
            ->when(
                $attendance === DriverAttendanceFilter::CheckedIn,
                fn ($query) => $query->checkedInToday(),
            )
            ->when(
                $attendance === DriverAttendanceFilter::NotCheckedIn,
                fn ($query) => $query->notCheckedInToday(),
            )
            ->orderBy('name_en')
            ->orderBy('id')
            ->get();

        if ($drivers->isEmpty()) {
            return [];
        }

        $driverIds = $drivers->modelKeys();
        $locations = DriverLocationModel::query()
            ->whereIn('driver_id', $driverIds)
            ->get()
            ->keyBy('driver_id');

        $tripsByDriver = TripModel::query()
            ->whereIn('driver_id', $driverIds)
            ->whereIn('status', [
                TripStatus::Going->value,
                TripStatus::AtDestination->value,
                TripStatus::Returning->value,
            ])
            ->orderByDesc('going_started_at')
            ->orderByDesc('id')
            ->get()
            ->groupBy('driver_id');

        $result = [];
        foreach ($drivers as $driver) {
            $location = $locations->get($driver->id);
            $group = $tripsByDriver->get($driver->id);
            $tripModel = null;
            if ($group !== null && $group->isNotEmpty()) {
                $tracked = $location?->trip_id !== null
                    ? $group->firstWhere('id', $location->trip_id)
                    : null;
                $tripModel = $tracked ?? $group->first();
            }

            $updatedAt = $location?->updated_at !== null
                ? DateTimeImmutable::createFromMutable($location->updated_at)
                : null;
            // Flutter DriverLocation.isStale: age > staleThreshold (exact 60s is not stale).
            $isStale = $updatedAt === null
                || ($nowTs - $updatedAt->getTimestamp()) > $staleSeconds;

            $state = $tripModel !== null
                ? LiveMapState::OnTrip
                : ($driver->isAvailableNow()
                    ? LiveMapState::Available
                    : LiveMapState::Unavailable);

            $result[] = new LiveMapDriver(
                driver: DriverMapper::toDomain($driver),
                trip: $tripModel !== null ? TripMapper::toDomain($tripModel) : null,
                state: $state,
                lat: $location !== null ? (float) $location->lat : null,
                lng: $location !== null ? (float) $location->lng : null,
                heading: $location !== null ? (float) $location->heading : null,
                speed: $location !== null ? (float) $location->speed : null,
                accuracy: $location !== null ? (float) $location->accuracy : null,
                updatedAt: $updatedAt,
                isStale: $isStale,
                isTracking: $location !== null ? (bool) $location->is_tracking : false,
            );
        }

        return $result;
    }

    public function upsertLastKnownIfNewer(
        string $driverId,
        float $lat,
        float $lng,
        DateTimeImmutable $observedAt,
    ): void {
        $write = function () use ($driverId, $lat, $lng, $observedAt): void {
            $model = DriverLocationModel::query()->whereKey($driverId)->lockForUpdate()->first();

            if ($model !== null
                && $model->updated_at !== null
                && $observedAt->getTimestamp() <= $model->updated_at->getTimestamp()) {
                return;
            }

            if ($model === null) {
                $model = new DriverLocationModel;
                $model->driver_id = $driverId;
                $model->trip_id = null;
                $model->heading = 0;
                $model->speed = 0;
                $model->accuracy = 0;
                $model->is_tracking = false;
            }

            $model->lat = $lat;
            $model->lng = $lng;
            $model->updated_at = $observedAt;
            $model->save();
        };

        if (DB::transactionLevel() > 0) {
            $write();

            return;
        }

        DB::transaction($write);
    }
}
