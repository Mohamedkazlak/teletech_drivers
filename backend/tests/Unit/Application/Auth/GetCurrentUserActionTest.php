<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Auth;

use App\Application\Auth\Actions\GetCurrentUserAction;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\UserNotFoundException;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeUserRepository;

final class GetCurrentUserActionTest extends TestCase
{
    public function test_it_returns_user(): void
    {
        $users = new FakeUserRepository;
        $users->seed(new User(
            id: 'u1',
            nameEn: 'Jane',
            nameAr: null,
            email: 'jane@example.com',
            passwordHash: 'hash',
            role: UserRole::Employee,
            isActive: true,
            phone: null,
            branch: null,
            availabilityStatus: AvailabilityStatus::Unavailable,
        ));

        $action = new GetCurrentUserAction($users);

        $this->assertSame('jane@example.com', $action->execute('u1')->email);
    }

    public function test_it_throws_when_missing(): void
    {
        $action = new GetCurrentUserAction(new FakeUserRepository);

        $this->expectException(UserNotFoundException::class);
        $action->execute('missing');
    }
}
