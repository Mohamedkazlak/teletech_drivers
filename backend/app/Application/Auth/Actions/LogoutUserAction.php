<?php

declare(strict_types=1);

namespace App\Application\Auth\Actions;

use App\Application\Contracts\TokenIssuerInterface;

final class LogoutUserAction
{
    public function __construct(
        private readonly TokenIssuerInterface $tokenIssuer,
    ) {}

    public function execute(string $userId): void
    {
        $this->tokenIssuer->revokeCurrentToken($userId);
    }
}
