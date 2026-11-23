<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Drivers;

use App\Application\Drivers\Actions\GetOwnDriverProfileAction;
use App\Domain\Entities\Driver;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeDriverRepository;

final class GetOwnDriverProfileActionTest extends TestCase
{
    public function test_it_returns_own_profile(): void
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
            nationalId: 'secret-nid',
            carLicense: 'car',
            personalLicense: 'pers',
            favoritePlaceIds: [],
        ));

        $driver = (new GetOwnDriverProfileAction($drivers))->execute('d1');

        $this->assertSame('secret-nid', $driver->nationalId);
    }
}
