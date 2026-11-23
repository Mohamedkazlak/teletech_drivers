<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Domain\Entities\TripReport;
use App\Domain\Exceptions\TripNotFoundException;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Services\TripReportBuilder;

final class GetTripReportAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly TripReportBuilder $builder,
    ) {}

    public function execute(string $tripId): TripReport
    {
        $trip = $this->trips->findById($tripId);
        if ($trip === null) {
            throw new TripNotFoundException;
        }

        return $this->builder->build($trip, $this->trips->trackingPoints($tripId));
    }
}
