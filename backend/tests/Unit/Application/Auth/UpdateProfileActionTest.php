<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Auth;

use App\Application\Auth\Actions\UpdateProfileAction;
use App\Application\Auth\DTOs\UpdateProfileData;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeUserRepository;

final class UpdateProfileActionTest extends TestCase
{
    public function test_it_merges_only_present_fields_and_keeps_role(): void
    {
        $users = new FakeUserRepository;
        $users->seed(new User(
            id: 'u1',
            nameEn: 'Old',
            nameAr: 'قديم',
            email: 'jane@example.com',
            passwordHash: 'hash',
            role: UserRole::Employee,
            isActive: true,
            phone: '011',
            branch: Branch::CompanyHeadquarters,
            availabilityStatus: AvailabilityStatus::Available,
        ));

        $action = new UpdateProfileAction($users);
        $updated = $action->execute(new UpdateProfileData(
            userId: 'u1',
            changes: [
                'name_en' => 'New Name',
                'phone' => '012',
                'branch' => Branch::NewHeadquarters,
                'role' => UserRole::Admin,
                'is_active' => false,
            ],
        ));

        $this->assertSame('New Name', $updated->nameEn);
        $this->assertSame('قديم', $updated->nameAr);
        $this->assertSame('012', $updated->phone);
        $this->assertSame(Branch::NewHeadquarters, $updated->branch);
        $this->assertSame('jane@example.com', $updated->email);
        $this->assertSame(UserRole::Employee, $updated->role);
        $this->assertTrue($updated->isActive);

        $withEmail = $action->execute(new UpdateProfileData(
            userId: 'u1',
            changes: [
                'email' => 'jane.new@example.com',
                'name_ar' => 'جديد',
            ],
        ));

        $this->assertSame('jane.new@example.com', $withEmail->email);
        $this->assertSame('جديد', $withEmail->nameAr);
        $this->assertSame('New Name', $withEmail->nameEn);
    }
}
