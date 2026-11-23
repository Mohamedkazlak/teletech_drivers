<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Application\Contracts\TokenIssuerInterface;
use App\Domain\Entities\User;

final class FakeTokenIssuer implements TokenIssuerInterface
{
    /** @var list<string> */
    public array $issued = [];

    /** @var list<string> */
    public array $revokedUserIds = [];

    /** @var list<string> */
    public array $revokedOtherUserIds = [];

    /** @var list<string> */
    public array $revokedAllUserIds = [];

    public function issue(User $user, string $tokenName = 'auth'): string
    {
        $token = 'token-'.$user->id;
        $this->issued[] = $token;

        return $token;
    }

    public function revokeCurrentToken(string $userId): void
    {
        $this->revokedUserIds[] = $userId;
    }

    public function revokeOtherTokens(string $userId): void
    {
        $this->revokedOtherUserIds[] = $userId;
    }

    public function revokeAllTokens(string $userId): void
    {
        $this->revokedAllUserIds[] = $userId;
    }
}
