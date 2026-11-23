<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Drivers;

use App\Application\Drivers\Actions\SoftDeleteDriverAction;
use App\Domain\Entities\Driver;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\UserRole;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakeDriverRepository;
use Tests\Support\FakeTokenIssuer;

final class SoftDeleteDriverActionTest extends TestCase
{
    public function test_it_soft_deletes_and_revokes_tokens(): void
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
            nationalId: '',
            carLicense: '',
            personalLicense: '',
            favoritePlaceIds: [],
        ));

        $tokens = new FakeTokenIssuer;
        $action = new SoftDeleteDriverAction($drivers, $tokens);

        $result = $action->execute('d1', 'admin-1');

        $this->assertFalse($result->user->isActive);
        $this->assertNotNull($result->user->deletedAt);
        $this->assertSame('admin-1', $result->user->deletedBy);
        $this->assertSame(['d1'], $tokens->revokedAllUserIds);
    }
}
