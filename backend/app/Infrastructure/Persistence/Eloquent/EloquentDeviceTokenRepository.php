<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Entities\DeviceToken as DeviceTokenEntity;
use App\Domain\Enums\DevicePlatform;
use App\Domain\Repositories\DeviceTokenRepositoryInterface;
use App\Models\DeviceToken as DeviceTokenModel;
use DateTimeImmutable;

final class EloquentDeviceTokenRepository implements DeviceTokenRepositoryInterface
{
    public function upsert(
        string $userId,
        string $token,
        DevicePlatform $platform,
        string $locale,
        DateTimeImmutable $seenAt,
    ): void {
        DeviceTokenModel::query()->updateOrCreate(
            ['token' => $token],
            [
                'user_id' => $userId,
                'platform' => $platform,
                'locale' => $locale === 'ar' ? 'ar' : 'en',
                'last_seen_at' => $seenAt,
            ],
        );
    }

    public function deleteForUser(string $userId, string $token): void
    {
        DeviceTokenModel::query()
            ->where('user_id', $userId)
            ->where('token', $token)
            ->delete();
    }

    public function deleteByToken(string $token): void
    {
        DeviceTokenModel::query()->where('token', $token)->delete();
    }

    public function listForUser(string $userId): array
    {
        return DeviceTokenModel::query()
            ->where('user_id', $userId)
            ->orderBy('id')
            ->get()
            ->map(static function (DeviceTokenModel $model): DeviceTokenEntity {
                return new DeviceTokenEntity(
                    id: (string) $model->id,
                    userId: (string) $model->user_id,
                    token: (string) $model->token,
                    platform: $model->platform,
                    locale: (string) $model->locale,
                );
            })
            ->values()
            ->all();
    }
}
