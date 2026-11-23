<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Drivers;

use App\Application\Drivers\Actions\RestoreDriverAction;
use App\Domain\Entities\Driver;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeDriverRepository;

final class RestoreDriverActionTest extends TestCase
{
    public function test_it_restores_driver(): void
    {
        $drivers = new FakeDriverRepository;
        $drivers->seed(new Driver(
            user: new User(
                id: 'd1',
                nameEn: 'Driver',
                nameAr: null,
                email: 'd@example.com',
                passwordHash: 'hash',
                role: UserRole::Driver,
                isActive: false,
                phone: null,
                branch: null,
                availabilityStatus: AvailabilityStatus::Unavailable,
                deletedAt: now()->toIso8601String(),
                deletedBy: 'admin-1',
            ),
            nationalId: '',
            carLicense: '',
            personalLicense: '',
            favoritePlaceIds: [],
        ));

        $result = (new RestoreDriverAction($drivers))->execute('d1');

        $this->assertTrue($result->user->isActive);
        $this->assertNull($result->user->deletedAt);
        $this->assertNull($result->user->deletedBy);
    }
}
