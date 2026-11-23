<?php

declare(strict_types=1);

namespace App\Application\Drivers\Actions;

use App\Domain\Entities\Driver;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\DriverRepositoryInterface;

final class GetOwnDriverProfileAction
{
    public function __construct(
        private readonly DriverRepositoryInterface $drivers,
    ) {}

    public function execute(string $userId): Driver
    {
        $driver = $this->drivers->findById($userId);

        if ($driver === null) {
            throw new UserNotFoundException;
        }

        return $driver;
    }
}
