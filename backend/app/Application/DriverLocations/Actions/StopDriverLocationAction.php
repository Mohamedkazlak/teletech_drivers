<?php

declare(strict_types=1);

namespace App\Application\DriverLocations\Actions;

use App\Application\Realtime\RealtimePublisher;
use App\Domain\Entities\DriverLocation;
use App\Domain\Repositories\DriverLocationRepositoryInterface;

final class StopDriverLocationAction
{
    public function __construct(
        private readonly DriverLocationRepositoryInterface $locations,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(string $driverId): DriverLocation
    {
        $location = $this->locations->stopTracking($driverId);
        $this->realtime->location($location, 'stopped');

        return $location;
    }
}
