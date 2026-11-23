<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Drivers;

use App\Application\Drivers\Actions\UpdateDriverAction;
use App\Application\Drivers\DTOs\UpdateDriverData;
use App\Domain\Entities\Driver;
use App\Domain\Entities\Place;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeDriverRepository;
use Tests\Support\FakePasswordHasher;
use Tests\Support\FakePlaceRepository;

final class UpdateDriverActionTest extends TestCase
{
    public function test_it_updates_driver_and_optional_password(): void
    {
        $places = new FakePlaceRepository;
        $places->seed(new Place('p1', 'HQ', 'مقر', null, null, null, true, true));

        $drivers = new FakeDriverRepository($places);
        $drivers->seed(new Driver(
            user: new User(
                id: 'd1',
                nameEn: 'Old',
                nameAr: 'قديم',
                email: 'd@example.com',
                passwordHash: 'hash:old',
                role: UserRole::Driver,
                isActive: true,
                phone: null,
                branch: null,
                availabilityStatus: AvailabilityStatus::Unavailable,
            ),
            nationalId: 'n',
            carLicense: 'c',
            personalLicense: 'p',
            favoritePlaceIds: [],
        ));

        $action = new UpdateDriverAction($drivers, new FakePasswordHasher);

        $updated = $action->execute(new UpdateDriverData(
            id: 'd1',
            nameEn: 'New',
            nameAr: 'جديد',
            phone: '011',
            nationalId: 'n2',
            carLicense: 'c2',
            personalLicense: 'p2',
            favoritePlaceIds: ['p1'],
            isActive: true,
            password: 'newpass',
        ));

        $this->assertSame('New', $updated->user->nameEn);
        $this->assertSame('hash:newpass', $updated->user->passwordHash);
        $this->assertSame('n2', $updated->nationalId);
    }
}
