<?php

declare(strict_types=1);

namespace App\Application\Users\DTOs;

final readonly class ResetUserPasswordData
{
    public function __construct(
        public string $actorId,
        public string $userId,
        public string $password,
    ) {}
}
