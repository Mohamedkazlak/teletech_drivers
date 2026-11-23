<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent\Mappers;

use App\Domain\Entities\User as UserEntity;
use App\Domain\Enums\AvailabilityStatus;
use App\Models\User as UserModel;

final class UserMapper
{
    public static function toDomain(UserModel $model): UserEntity
    {
        return new UserEntity(
            id: (string) $model->id,
            nameEn: $model->name_en,
            nameAr: $model->name_ar,
            email: $model->email,
            passwordHash: $model->getAuthPassword(),
            role: $model->role,
            isActive: (bool) $model->is_active,
            phone: $model->phone,
            branch: $model->branch,
            availabilityStatus: $model->isAvailableNow()
                ? AvailabilityStatus::Available
                : AvailabilityStatus::Unavailable,
            deletedAt: $model->deleted_at?->format(DATE_ATOM),
            deletedBy: $model->deleted_by !== null ? (string) $model->deleted_by : null,
            mustChangePassword: (bool) $model->must_change_password,
        );
    }
}
