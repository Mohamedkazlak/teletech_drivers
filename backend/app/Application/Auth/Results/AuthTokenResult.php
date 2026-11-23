<?php

declare(strict_types=1);

namespace App\Application\Auth\Results;

use App\Domain\Entities\User;

final readonly class AuthTokenResult
{
    public function __construct(
        public User $user,
        public string $token,
    ) {}
}
