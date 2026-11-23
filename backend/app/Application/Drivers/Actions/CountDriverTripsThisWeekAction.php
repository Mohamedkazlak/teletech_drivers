<?php

declare(strict_types=1);

namespace App\Application\Drivers\Actions;

use App\Domain\Repositories\TripRepositoryInterface;

/**
 * Non-cancelled trips in the current Saturday fleet week, one grouped query.
 */
final class CountDriverTripsThisWeekAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
    ) {}

    /**
     * @param  list<string>  $driverIds
     * @return array<string, int>
     */
    public function execute(array $driverIds): array
    {
        return $this->trips->countNonCancelledThisWeek($driverIds);
    }
}
