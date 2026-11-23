<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Actions;

use App\Application\Realtime\RealtimePublisher;
use App\Application\TripRequests\DTOs\RejectTripRequestData;
use App\Domain\Entities\TripRequest;
use App\Domain\Repositories\TripRequestRepositoryInterface;
use DateTimeImmutable;

final class RejectTripRequestAction
{
    public function __construct(
        private readonly TripRequestRepositoryInterface $tripRequests,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(RejectTripRequestData $data): TripRequest
    {
        $request = $this->tripRequests->reject(
            $data->requestId,
            $data->handledBy,
            new DateTimeImmutable('now'),
            $data->rejectionReason,
        );
        $this->realtime->tripRequest('trip-request.rejected', $request);

        return $request;
    }
}
