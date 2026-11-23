<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Drivers;

use App\Application\Drivers\Actions\GetDriverAction;
use App\Domain\Entities\Driver;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\UserNotFoundException;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeDriverRepository;

final class GetDriverActionTest extends TestCase
{
    public function test_it_returns_driver(): void
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
                isActive: true,
                phone: null,
                branch: null,
                availabilityStatus: AvailabilityStatus::Unavailable,
            ),
            nationalId: 'nid',
            carLicense: 'car',
            personalLicense: 'pers',
            favoritePlaceIds: [],
        ));

        $driver = (new GetDriverAction($drivers))->execute('d1');

        $this->assertSame('nid', $driver->nationalId);
    }

    public function test_it_throws_when_missing(): void
    {
        $this->expectException(UserNotFoundException::class);
        (new GetDriverAction(new FakeDriverRepository))->execute('missing');
    }
}
