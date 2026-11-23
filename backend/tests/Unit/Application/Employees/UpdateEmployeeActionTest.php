<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Employees;

use App\Application\Employees\Actions\UpdateEmployeeAction;
use App\Application\Employees\DTOs\UpdateEmployeeData;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakePasswordHasher;
use Tests\Support\FakeUserRepository;

final class UpdateEmployeeActionTest extends TestCase
{
    public function test_it_updates_employee_without_changing_email_role(): void
    {
        $users = new FakeUserRepository;
        $users->seed(new User(
            id: 'e1',
            nameEn: 'Old',
            nameAr: null,
            email: 'e@example.com',
            passwordHash: 'hash:old',
            role: UserRole::Employee,
            isActive: true,
            phone: null,
            branch: Branch::CompanyHeadquarters,
            availabilityStatus: AvailabilityStatus::Unavailable,
        ));

        $updated = (new UpdateEmployeeAction($users, new FakePasswordHasher))->execute(
            new UpdateEmployeeData(
                id: 'e1',
                nameEn: 'New',
                nameAr: 'جديد',
                phone: '011',
                branch: Branch::NewHeadquarters,
                isActive: true,
                password: null,
            ),
        );

        $this->assertSame('New', $updated->nameEn);
        $this->assertSame('e@example.com', $updated->email);
        $this->assertSame(UserRole::Employee, $updated->role);
        $this->assertSame('hash:old', $updated->passwordHash);
    }
}
