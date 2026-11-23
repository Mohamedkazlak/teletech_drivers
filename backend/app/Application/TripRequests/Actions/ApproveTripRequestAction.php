<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Actions;

use App\Application\Notifications\NotificationService;
use App\Application\Realtime\RealtimePublisher;
use App\Domain\Entities\TripRequest;
use App\Domain\Repositories\TripRequestRepositoryInterface;
use DateTimeImmutable;
use Illuminate\Support\Facades\DB;

final class ApproveTripRequestAction
{
    public function __construct(
        private readonly TripRequestRepositoryInterface $tripRequests,
        private readonly RealtimePublisher $realtime,
        private readonly NotificationService $notifications,
    ) {}

    public function execute(string $id, string $handledBy): TripRequest
    {
        $request = DB::transaction(function () use ($id, $handledBy): TripRequest {
            $request = $this->tripRequests->approve($id, $handledBy, new DateTimeImmutable('now'));
            $this->notifications->tripReadyToAssign($request, $handledBy);

            return $request;
        });
        $this->realtime->tripRequest('trip-request.approved', $request);

        return $request;
    }
}
