<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Services\TripRequest\CreateTripRequestStrategyFactory;
use DomainException;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

final class CreateTripRequestStrategyFactoryTest extends TestCase
{
    private CreateTripRequestStrategyFactory $factory;

    protected function setUp(): void
    {
        parent::setUp();
        $this->factory = new CreateTripRequestStrategyFactory;
    }

    /**
     * @return list<array{0: UserRole, 1: TripRequestStatus, 2: bool, 3: bool, 4: bool}>
     */
    public static function rolePlans(): array
    {
        return [
            [UserRole::Employee, TripRequestStatus::Pending, false, false, false],
            [UserRole::CompanyAdmin, TripRequestStatus::Approved, true, false, true],
            [UserRole::Admin, TripRequestStatus::Approved, true, false, true],
            [UserRole::DriversAdmin, TripRequestStatus::Approved, true, true, true],
        ];
    }

    #[DataProvider('rolePlans')]
    public function test_strategy_per_role(
        UserRole $role,
        TripRequestStatus $status,
        bool $autoApproved,
        bool $createTrip,
        bool $setHandledBy,
    ): void {
        $plan = $this->factory->forRole($role)->build();

        $this->assertSame($status, $plan->status);
        $this->assertSame($autoApproved, $plan->autoApproved);
        $this->assertSame($createTrip, $plan->createTrip);
        $this->assertSame($setHandledBy, $plan->setHandledBy);
        $this->assertSame($role, $plan->requesterRole);
    }

    public function test_driver_cannot_create(): void
    {
        $this->expectException(DomainException::class);
        $this->factory->forRole(UserRole::Driver);
    }
}
