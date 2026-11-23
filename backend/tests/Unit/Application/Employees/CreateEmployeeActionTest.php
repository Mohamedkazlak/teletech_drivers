<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Employees;

use App\Application\Employees\Actions\CreateEmployeeAction;
use App\Application\Employees\DTOs\CreateEmployeeData;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakePasswordHasher;
use Tests\Support\FakeUserRepository;

final class CreateEmployeeActionTest extends TestCase
{
    public function test_it_creates_employee(): void
    {
        $action = new CreateEmployeeAction(new FakeUserRepository, new FakePasswordHasher);

        $user = $action->execute(new CreateEmployeeData(
            nameEn: 'Emp',
            nameAr: 'موظف',
            email: 'e@example.com',
            password: 'secret123',
            phone: '010',
            branch: Branch::NewHeadquarters,
        ));

        $this->assertSame(UserRole::Employee, $user->role);
        $this->assertSame('hash:secret123', $user->passwordHash);
        $this->assertSame(Branch::NewHeadquarters, $user->branch);
        $this->assertTrue($user->mustChangePassword);
    }
}
