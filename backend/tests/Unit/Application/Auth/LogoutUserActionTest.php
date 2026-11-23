<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Auth;

use App\Application\Auth\Actions\LogoutUserAction;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeTokenIssuer;

final class LogoutUserActionTest extends TestCase
{
    public function test_it_revokes_current_token(): void
    {
        $tokens = new FakeTokenIssuer;
        $action = new LogoutUserAction($tokens);

        $action->execute('user-1');

        $this->assertSame(['user-1'], $tokens->revokedUserIds);
    }
}
