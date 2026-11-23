<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Drivers;

use App\Application\Drivers\Actions\ListDriversAction;
use App\Application\Drivers\DTOs\ListDriversData;
use App\Domain\Entities\Driver;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeDriverRepository;

final class ListDriversActionTest extends TestCase
{
    public function test_it_lists_active_drivers(): void
    {
        $drivers = new FakeDriverRepository;
        $drivers->seed($this->driver('d1', true));
        $drivers->seed($this->driver('d2', false));

        $result = (new ListDriversAction($drivers))->execute(new ListDriversData(
            isActive: true,
            attendance: null,
            search: null,
            includeDeleted: false,
        ));

        $this->assertSame(1, $result->total);
        $this->assertSame('d1', $result->items[0]->user->id);
    }

    private function driver(string $id, bool $active): Driver
    {
        return new Driver(
            user: new User(
                id: $id,
                nameEn: 'D '.$id,
                nameAr: null,
                email: $id.'@example.com',
                passwordHash: 'hash',
                role: UserRole::Driver,
                isActive: $active,
                phone: null,
                branch: null,
                availabilityStatus: AvailabilityStatus::Unavailable,
            ),
            nationalId: '',
            carLicense: '',
            personalLicense: '',
            favoritePlaceIds: [],
        );
    }
}
