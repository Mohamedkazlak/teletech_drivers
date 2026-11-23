<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Domain\Entities\Trip;
use App\Domain\Exceptions\TripNotFoundException;
use App\Domain\Repositories\TripRepositoryInterface;

final class GetTripAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
    ) {}

    public function execute(string $id): Trip
    {
        $trip = $this->trips->findById($id);
        if ($trip === null) {
            throw new TripNotFoundException;
        }

        return $trip;
    }
}
