<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Drivers;

use App\Application\Drivers\Actions\CreateDriverAction;
use App\Application\Drivers\DTOs\CreateDriverData;
use App\Domain\Entities\Place;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeDriverRepository;
use Tests\Support\FakePasswordHasher;
use Tests\Support\FakePlaceRepository;

final class CreateDriverActionTest extends TestCase
{
    public function test_it_creates_driver_with_hashed_password(): void
    {
        $places = new FakePlaceRepository;
        $places->seed(new Place('p1', 'HQ', 'مقر', 30.0, 31.0, null, true, true));

        $drivers = new FakeDriverRepository($places);
        $action = new CreateDriverAction($drivers, new FakePasswordHasher);

        $driver = $action->execute(new CreateDriverData(
            nameEn: 'Driver One',
            nameAr: 'سائق',
            email: 'driver@example.com',
            password: 'secret123',
            phone: '0100',
            nationalId: 'nid',
            carLicense: 'car',
            personalLicense: 'pers',
            favoritePlaceIds: ['p1'],
        ));

        $this->assertSame(UserRole::Driver, $driver->user->role);
        $this->assertSame('hash:secret123', $driver->user->passwordHash);
        $this->assertTrue($driver->user->mustChangePassword);
        $this->assertSame(['p1'], $driver->favoritePlaceIds);
    }
}
