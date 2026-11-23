<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Employees;

use App\Application\Employees\Actions\RestoreEmployeeAction;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeUserRepository;

final class RestoreEmployeeActionTest extends TestCase
{
    public function test_it_restores_employee(): void
    {
        $users = new FakeUserRepository;
        $users->seed(new User(
            id: 'e1',
            nameEn: 'Emp',
            nameAr: null,
            email: 'e@example.com',
            passwordHash: 'hash',
            role: UserRole::Employee,
            isActive: false,
            phone: null,
            branch: null,
            availabilityStatus: AvailabilityStatus::Unavailable,
            deletedAt: now()->toIso8601String(),
            deletedBy: 'admin-1',
        ));

        $result = (new RestoreEmployeeAction($users))->execute('e1');

        $this->assertTrue($result->isActive);
        $this->assertNull($result->deletedAt);
    }
}
