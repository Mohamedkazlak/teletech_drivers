<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Actions;

use App\Domain\Entities\TripRequest;
use App\Domain\Exceptions\TripRequestNotFoundException;
use App\Domain\Repositories\TripRequestRepositoryInterface;

final class GetTripRequestAction
{
    public function __construct(
        private readonly TripRequestRepositoryInterface $tripRequests,
    ) {}

    public function execute(string $id): TripRequest
    {
        $request = $this->tripRequests->findById($id);
        if ($request === null) {
            throw new TripRequestNotFoundException;
        }

        return $request;
    }
}
