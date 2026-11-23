<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent\Mappers;

use App\Domain\Entities\DriverLocation as DriverLocationEntity;
use App\Models\DriverLocation as DriverLocationModel;
use DateTimeImmutable;

final class DriverLocationMapper
{
    public static function toDomain(DriverLocationModel $model): DriverLocationEntity
    {
        return new DriverLocationEntity(
            driverId: (string) $model->driver_id,
            tripId: $model->trip_id !== null ? (string) $model->trip_id : null,
            lat: (float) $model->lat,
            lng: (float) $model->lng,
            heading: (float) $model->heading,
            speed: (float) $model->speed,
            accuracy: (float) $model->accuracy,
            isTracking: (bool) $model->is_tracking,
            updatedAt: $model->updated_at !== null
                ? DateTimeImmutable::createFromMutable($model->updated_at)
                : null,
        );
    }
}
