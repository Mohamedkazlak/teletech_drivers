<?php

declare(strict_types=1);

namespace App\Application\Drivers\Actions;

use App\Domain\Entities\Driver;
use App\Domain\Repositories\DriverRepositoryInterface;

final class RestoreDriverAction
{
    public function __construct(
        private readonly DriverRepositoryInterface $drivers,
    ) {}

    public function execute(string $driverId): Driver
    {
        return $this->drivers->restore($driverId);
    }
}
