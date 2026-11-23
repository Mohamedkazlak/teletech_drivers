<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Employees;

use App\Application\Employees\Actions\GetEmployeeAction;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\UserNotFoundException;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeUserRepository;

final class GetEmployeeActionTest extends TestCase
{
    public function test_it_returns_employee(): void
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

        $user = (new GetEmployeeAction($users))->execute('e1');

        $this->assertSame('e@example.com', $user->email);
    }

    public function test_it_rejects_non_employee(): void
    {
        $users = new FakeUserRepository;
        $users->seed(new User(
            id: 'd1',
            nameEn: 'Driver',
            nameAr: null,
            email: 'd@example.com',
            passwordHash: 'hash',
            role: UserRole::Driver,
            isActive: true,
            phone: null,
            branch: null,
            availabilityStatus: AvailabilityStatus::Unavailable,
        ));

        $this->expectException(UserNotFoundException::class);
        (new GetEmployeeAction($users))->execute('d1');
    }
}
