<?php

declare(strict_types=1);

namespace App\Application\Drivers\Actions;

use App\Domain\Entities\DriverStats;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Services\StatsAggregator;

final class GetDriverStatsAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly StatsAggregator $aggregator,
    ) {}

    public function execute(string $driverId, string $period, ?string $date): DriverStats
    {
        return $this->aggregator->aggregate(
            $period,
            $date,
            $this->trips->listCountableTrips($driverId, $period, $date),
        );
    }
}
