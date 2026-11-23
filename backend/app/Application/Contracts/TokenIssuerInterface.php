<?php

declare(strict_types=1);

namespace App\Application\Contracts;

use App\Domain\Entities\User;

interface TokenIssuerInterface
{
    public function issue(User $user, string $tokenName = 'auth'): string;

    public function revokeCurrentToken(string $userId): void;

    public function revokeOtherTokens(string $userId): void;

    public function revokeAllTokens(string $userId): void;
}
