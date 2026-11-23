<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Employees;

use App\Application\Employees\Actions\ListEmployeesAction;
use App\Application\Employees\DTOs\ListEmployeesData;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeUserRepository;

final class ListEmployeesActionTest extends TestCase
{
    public function test_it_filters_by_branch(): void
    {
        $users = new FakeUserRepository;
        $users->seed(new User(
            id: 'e1',
            nameEn: 'A',
            nameAr: null,
            email: 'a@example.com',
            passwordHash: 'hash',
            role: UserRole::Employee,
            isActive: true,
            phone: null,
            branch: Branch::CompanyHeadquarters,
            availabilityStatus: AvailabilityStatus::Unavailable,
        ));
        $users->seed(new User(
            id: 'e2',
            nameEn: 'B',
            nameAr: null,
            email: 'b@example.com',
            passwordHash: 'hash',
            role: UserRole::Employee,
            isActive: true,
            phone: null,
            branch: Branch::NewHeadquarters,
            availabilityStatus: AvailabilityStatus::Unavailable,
        ));

        $result = (new ListEmployeesAction($users))->execute(new ListEmployeesData(
            isActive: null,
            branch: Branch::NewHeadquarters,
            search: null,
            includeDeleted: false,
        ));

        $this->assertSame(1, $result->total);
        $this->assertSame('e2', $result->items[0]->id);
    }
}
