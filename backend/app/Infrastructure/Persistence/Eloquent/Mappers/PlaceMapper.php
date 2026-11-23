<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent\Mappers;

use App\Domain\Entities\Place as PlaceEntity;
use App\Models\Place as PlaceModel;
use DateTimeImmutable;

final class PlaceMapper
{
    public static function toDomain(PlaceModel $model): PlaceEntity
    {
        return new PlaceEntity(
            id: (string) $model->id,
            nameEn: $model->name_en,
            nameAr: $model->name_ar,
            latitude: $model->latitude !== null ? (float) $model->latitude : null,
            longitude: $model->longitude !== null ? (float) $model->longitude : null,
            address: $model->address,
            isHeadquarters: (bool) $model->is_headquarters,
            isActive: (bool) $model->is_active,
            createdAt: $model->created_at !== null
                ? DateTimeImmutable::createFromMutable($model->created_at)
                : null,
        );
    }
}
