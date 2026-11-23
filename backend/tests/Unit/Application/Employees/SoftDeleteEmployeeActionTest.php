<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Employees;

use App\Application\Employees\Actions\SoftDeleteEmployeeAction;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeTokenIssuer;
use Tests\Support\FakeUserRepository;

final class SoftDeleteEmployeeActionTest extends TestCase
{
    public function test_it_soft_deletes_and_revokes_tokens(): void
    {
        $users = new FakeUserRepository;
        $users->seed(new User(
            id: 'e1',
            nameEn: 'Emp',
            nameAr: null,
            email: 'e@example.com',
            passwordHash: 'hash',
            role: UserRole::Employee,
            isActive: true,
            phone: null,
            branch: null,
            availabilityStatus: AvailabilityStatus::Unavailable,
        ));

        $tokens = new FakeTokenIssuer;
        $result = (new SoftDeleteEmployeeAction($users, $tokens))->execute('e1', 'admin-1');

        $this->assertFalse($result->isActive);
        $this->assertSame(['e1'], $tokens->revokedAllUserIds);
    }
}
