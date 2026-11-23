<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Auth;

use App\Application\Auth\Actions\RegisterUserAction;
use App\Application\Auth\DTOs\RegisterUserData;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakePasswordHasher;
use Tests\Support\FakeTokenIssuer;
use Tests\Support\FakeUserRepository;

final class RegisterUserActionTest extends TestCase
{
    public function test_it_creates_employee_and_returns_token(): void
    {
        $users = new FakeUserRepository;
        $hasher = new FakePasswordHasher;
        $tokens = new FakeTokenIssuer;
        $action = new RegisterUserAction($users, $hasher, $tokens);

        $result = $action->execute(new RegisterUserData(
            nameEn: 'Jane Doe',
            nameAr: 'جين',
            email: 'jane@example.com',
            password: 'secret123',
            phone: '01000000000',
            branch: Branch::CompanyHeadquarters,
        ));

        $this->assertSame(UserRole::Employee, $result->user->role);
        $this->assertFalse($result->user->mustChangePassword);
        $this->assertSame('jane@example.com', $result->user->email);
        $this->assertSame('hash:secret123', $result->user->passwordHash);
        $this->assertSame('token-'.$result->user->id, $result->token);
    }
}
