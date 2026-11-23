<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Auth;

use App\Application\Auth\Actions\ChangePasswordAction;
use App\Application\Auth\DTOs\ChangePasswordData;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\InactiveUserException;
use App\Domain\Exceptions\InvalidCurrentPasswordException;
use App\Domain\Exceptions\UserNotFoundException;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakePasswordHasher;
use Tests\Support\FakeTokenIssuer;
use Tests\Support\FakeUserRepository;

final class ChangePasswordActionTest extends TestCase
{
    public function test_it_updates_password_and_revokes_other_tokens(): void
    {
        $users = new FakeUserRepository;
        $hasher = new FakePasswordHasher;
        $tokens = new FakeTokenIssuer;

        $users->seed($this->user($hasher->hash('old-password'), true));

        $action = new ChangePasswordAction($users, $hasher, $tokens);
        $action->execute(new ChangePasswordData('u1', 'old-password', 'new-password-123'));

        $this->assertSame('hash:new-password-123', $users->findById('u1')?->passwordHash);
        $this->assertFalse($users->findById('u1')?->mustChangePassword);
        $this->assertSame(['u1'], $tokens->revokedOtherUserIds);
        $this->assertSame([], $tokens->revokedUserIds);
        $this->assertSame([], $tokens->revokedAllUserIds);
    }

    public function test_it_rejects_wrong_current_password(): void
    {
        $users = new FakeUserRepository;
        $hasher = new FakePasswordHasher;
        $tokens = new FakeTokenIssuer;
        $users->seed($this->user($hasher->hash('old-password'), true));

        $action = new ChangePasswordAction($users, $hasher, $tokens);

        try {
            $action->execute(new ChangePasswordData('u1', 'nope', 'new-password-123'));
            $this->fail('Expected invalid current password.');
        } catch (InvalidCurrentPasswordException) {
            $this->assertSame('hash:old-password', $users->findById('u1')?->passwordHash);
            $this->assertSame([], $tokens->revokedOtherUserIds);
        }
    }

    public function test_it_rejects_inactive_user(): void
    {
        $users = new FakeUserRepository;
        $hasher = new FakePasswordHasher;
        $users->seed($this->user($hasher->hash('old-password'), false));

        $action = new ChangePasswordAction($users, $hasher, new FakeTokenIssuer);

        $this->expectException(InactiveUserException::class);
        $action->execute(new ChangePasswordData('u1', 'old-password', 'new-password-123'));
    }

    public function test_it_rejects_missing_user(): void
    {
        $action = new ChangePasswordAction(
            new FakeUserRepository,
            new FakePasswordHasher,
            new FakeTokenIssuer,
        );

        $this->expectException(UserNotFoundException::class);
        $action->execute(new ChangePasswordData('missing', 'old-password', 'new-password-123'));
    }

    private function user(string $passwordHash, bool $isActive): User
    {
        return new User(
            id: 'u1',
            nameEn: 'Jane',
            nameAr: null,
            email: 'jane@example.com',
            passwordHash: $passwordHash,
            role: UserRole::Employee,
            isActive: $isActive,
            phone: null,
            branch: null,
            availabilityStatus: AvailabilityStatus::Unavailable,
            mustChangePassword: true,
        );
    }
}
