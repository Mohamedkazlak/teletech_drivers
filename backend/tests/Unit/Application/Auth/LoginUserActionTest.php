<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Auth;

use App\Application\Auth\Actions\LoginUserAction;
use App\Application\Auth\DTOs\LoginUserData;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\InactiveUserException;
use App\Domain\Exceptions\InvalidCredentialsException;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakePasswordHasher;
use Tests\Support\FakeTokenIssuer;
use Tests\Support\FakeUserRepository;

final class LoginUserActionTest extends TestCase
{
    public function test_it_logs_in_active_user(): void
    {
        $users = new FakeUserRepository;
        $hasher = new FakePasswordHasher;
        $tokens = new FakeTokenIssuer;

        $users->seed(new User(
            id: 'u1',
            nameEn: 'Jane',
            nameAr: null,
            email: 'jane@example.com',
            passwordHash: $hasher->hash('secret123'),
            role: UserRole::Employee,
            isActive: true,
            phone: null,
            branch: Branch::NewHeadquarters,
            availabilityStatus: AvailabilityStatus::Unavailable,
        ));

        $action = new LoginUserAction($users, $hasher, $tokens);
        $result = $action->execute(new LoginUserData('jane@example.com', 'secret123'));

        $this->assertSame('u1', $result->user->id);
        $this->assertSame('token-u1', $result->token);
    }

    public function test_it_rejects_invalid_credentials(): void
    {
        $users = new FakeUserRepository;
        $action = new LoginUserAction($users, new FakePasswordHasher, new FakeTokenIssuer);

        $this->expectException(InvalidCredentialsException::class);
        $action->execute(new LoginUserData('missing@example.com', 'x'));
    }

    public function test_it_rejects_inactive_user(): void
    {
        $users = new FakeUserRepository;
        $hasher = new FakePasswordHasher;

        $users->seed(new User(
            id: 'u2',
            nameEn: 'Inactive',
            nameAr: null,
            email: 'inactive@example.com',
            passwordHash: $hasher->hash('secret123'),
            role: UserRole::Employee,
            isActive: false,
            phone: null,
            branch: null,
            availabilityStatus: AvailabilityStatus::Unavailable,
        ));

        $action = new LoginUserAction($users, $hasher, new FakeTokenIssuer);

        $this->expectException(InactiveUserException::class);
        $action->execute(new LoginUserData('inactive@example.com', 'secret123'));
    }
}
