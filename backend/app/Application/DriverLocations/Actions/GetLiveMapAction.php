<?php

declare(strict_types=1);

namespace App\Application\DriverLocations\Actions;

use App\Domain\Entities\LiveMapDriver;
use App\Domain\Enums\DriverAttendanceFilter;
use App\Domain\Repositories\DriverLocationRepositoryInterface;

final class GetLiveMapAction
{
    public function __construct(
        private readonly DriverLocationRepositoryInterface $locations,
    ) {}

    /**
     * @return list<LiveMapDriver>
     */
    public function execute(?string $driverId = null, ?DriverAttendanceFilter $attendance = null): array
    {
        return $this->locations->listLiveMap($driverId, $attendance);
    }
}
