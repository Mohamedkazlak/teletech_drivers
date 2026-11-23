<?php

declare(strict_types=1);

namespace App\Application\Drivers\Actions;

use App\Application\Contracts\TokenIssuerInterface;
use App\Domain\Entities\Driver;
use App\Domain\Repositories\DriverRepositoryInterface;

final class SoftDeleteDriverAction
{
    public function __construct(
        private readonly DriverRepositoryInterface $drivers,
        private readonly TokenIssuerInterface $tokenIssuer,
    ) {}

    public function execute(string $driverId, string $actorId): Driver
    {
        $driver = $this->drivers->softDelete($driverId, $actorId);
        $this->tokenIssuer->revokeAllTokens($driverId);

        return $driver;
    }
}
