<?php

declare(strict_types=1);

namespace App\Domain\Repositories;

use App\Domain\Entities\DeviceToken;
use App\Domain\Enums\DevicePlatform;
use DateTimeImmutable;

interface DeviceTokenRepositoryInterface
{
    public function upsert(
        string $userId,
        string $token,
        DevicePlatform $platform,
        string $locale,
        DateTimeImmutable $seenAt,
    ): void;

    public function deleteForUser(string $userId, string $token): void;

    public function deleteByToken(string $token): void;

    /**
     * @return list<DeviceToken>
     */
    public function listForUser(string $userId): array;
}
