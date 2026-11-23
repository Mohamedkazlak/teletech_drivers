<?php

declare(strict_types=1);

namespace App\Application\Auth\DTOs;

final readonly class ChangePasswordData
{
    public function __construct(
        public string $userId,
        public string $currentPassword,
        public string $password,
    ) {}
}
