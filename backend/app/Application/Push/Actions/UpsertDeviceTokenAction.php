<?php

declare(strict_types=1);

namespace App\Application\Push\Actions;

use App\Domain\Enums\DevicePlatform;
use App\Domain\Repositories\DeviceTokenRepositoryInterface;
use DateTimeImmutable;

final class UpsertDeviceTokenAction
{
    public function __construct(private readonly DeviceTokenRepositoryInterface $tokens) {}

    public function execute(string $userId, string $token, DevicePlatform $platform, string $locale): void
    {
        $this->tokens->upsert(
            userId: $userId,
            token: $token,
            platform: $platform,
            locale: $locale === 'ar' ? 'ar' : 'en',
            seenAt: new DateTimeImmutable,
        );
    }
}
