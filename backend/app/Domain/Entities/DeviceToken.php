<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\DevicePlatform;

final readonly class DeviceToken
{
    public function __construct(
        public string $id,
        public string $userId,
        public string $token,
        public DevicePlatform $platform,
        public string $locale,
    ) {}
}
