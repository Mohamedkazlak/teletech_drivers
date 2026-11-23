<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent\Mappers;

use App\Domain\Entities\Driver as DriverEntity;
use App\Models\User as UserModel;

final class DriverMapper
{
    public static function toDomain(UserModel $model): DriverEntity
    {
        $profile = $model->driverProfile;

        /** @var list<string> $favoriteIds */
        $favoriteIds = $model->relationLoaded('favoritePlaces')
            ? $model->favoritePlaces->pluck('id')->map(fn ($id): string => (string) $id)->values()->all()
            : [];

        $today = $model->relationLoaded('todayAttendance')
            ? $model->getRelation('todayAttendance')
            : null;

        return new DriverEntity(
            user: UserMapper::toDomain($model),
            nationalId: $profile?->national_id ?? '',
            carLicense: $profile?->car_license ?? '',
            personalLicense: $profile?->personal_license ?? '',
            favoritePlaceIds: $favoriteIds,
            checkInDistanceM: $today instanceof \App\Models\AttendanceLog
                ? $today->check_in_distance_m
                : null,
        );
    }
}
