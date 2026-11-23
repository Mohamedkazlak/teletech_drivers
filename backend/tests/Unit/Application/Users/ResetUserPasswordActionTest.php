<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Users;

use App\Application\Users\Actions\ResetUserPasswordAction;
use App\Application\Users\DTOs\ResetUserPasswordData;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\CannotActOnSelfException;
use App\Domain\Exceptions\UserNotFoundException;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakePasswordHasher;
use Tests\Support\FakeTokenIssuer;
use Tests\Support\FakeUserRepository;

final class ResetUserPasswordActionTest extends TestCase
{
    public function test_it_sets_a_temporary_password_and_revokes_sessions(): void
    {
        $users = new FakeUserRepository;
        $users->seed($this->user('u1', UserRole::Driver));
        $tokens = new FakeTokenIssuer;

        $result = $this->action($users, $tokens)->execute(new ResetUserPasswordData(
            actorId: 'admin-1',
            userId: 'u1',
            password: 'temporary1',
        ));

        $this->assertTrue($result->mustChangePassword);
        $this->assertSame('hash:temporary1', $result->passwordHash);
        $this->assertSame(['u1'], $tokens->revokedAllUserIds);
    }

    public function test_it_rejects_resetting_your_own_password(): void
    {
        $users = new FakeUserRepository;
        $users->seed($this->user('admin-1', UserRole::Admin));

        $this->expectException(CannotActOnSelfException::class);

        $this->action($users, new FakeTokenIssuer)->execute(new ResetUserPasswordData(
            actorId: 'admin-1',
            userId: 'admin-1',
            password: 'temporary1',
        ));
    }

    public function test_it_rejects_a_missing_user(): void
    {
        $this->expectException(UserNotFoundException::class);

        $this->action(new FakeUserRepository, new FakeTokenIssuer)->execute(new ResetUserPasswordData(
            actorId: 'admin-1',
            userId: 'missing',
            password: 'temporary1',
        ));
    }

    private function action(FakeUserRepository $users, FakeTokenIssuer $tokens): ResetUserPasswordAction
    {
        return new ResetUserPasswordAction($users, new FakePasswordHasher, $tokens);
    }

    private function user(string $id, UserRole $role): User
    {
        return new User(
            id: $id,
            nameEn: 'User',
            nameAr: null,
            email: $id.'@example.com',
            passwordHash: 'hash:old',
            role: $role,
            isActive: true,
            phone: null,
            branch: null,
            availabilityStatus: AvailabilityStatus::Unavailable,
        );
    }
}
