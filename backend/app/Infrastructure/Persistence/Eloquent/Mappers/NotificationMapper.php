<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent\Mappers;

use App\Domain\Entities\Notification as NotificationEntity;
use App\Models\Notification as NotificationModel;
use DateTimeImmutable;

final class NotificationMapper
{
    public static function toDomain(NotificationModel $model): NotificationEntity
    {
        /** @var array<string, mixed> $params */
        $params = is_array($model->params) ? $model->params : [];

        return new NotificationEntity(
            id: (string) $model->id,
            userId: (string) $model->user_id,
            type: $model->type,
            titleKey: (string) $model->title_key,
            bodyKey: (string) $model->body_key,
            params: $params,
            tripRequestId: $model->trip_request_id !== null ? (string) $model->trip_request_id : null,
            tripId: $model->trip_id !== null ? (string) $model->trip_id : null,
            readAt: $model->read_at !== null
                ? DateTimeImmutable::createFromInterface($model->read_at)
                : null,
            createdAt: DateTimeImmutable::createFromInterface($model->created_at),
        );
    }
}
