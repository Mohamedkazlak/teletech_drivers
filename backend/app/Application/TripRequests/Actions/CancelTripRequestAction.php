<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Actions;

use App\Application\Realtime\RealtimePublisher;
use App\Domain\Entities\TripRequest;
use App\Domain\Repositories\TripRequestRepositoryInterface;

final class CancelTripRequestAction
{
    public function __construct(
        private readonly TripRequestRepositoryInterface $tripRequests,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(string $id): TripRequest
    {
        $request = $this->tripRequests->cancel($id);
        $this->realtime->tripRequest('trip-request.updated', $request);

        return $request;
    }
}
