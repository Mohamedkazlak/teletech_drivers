<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Actions;

use App\Application\Notifications\NotificationService;
use App\Application\Realtime\RealtimePublisher;
use App\Application\TripRequests\DTOs\ApproveGroupTripRequestsData;
use App\Domain\Entities\TripRequest;
use App\Domain\Repositories\TripRequestRepositoryInterface;
use DateTimeImmutable;
use Illuminate\Support\Facades\DB;

final class ApproveTripRequestsAsGroupAction
{
    public function __construct(
        private readonly TripRequestRepositoryInterface $tripRequests,
        private readonly RealtimePublisher $realtime,
        private readonly NotificationService $notifications,
    ) {}

    /**
     * @return list<TripRequest>
     */
    public function execute(ApproveGroupTripRequestsData $data): array
    {
        $requests = DB::transaction(function () use ($data): array {
            $requests = $this->tripRequests->approveAsGroup(
                array_values(array_unique($data->requestIds)),
                $data->handledBy,
                new DateTimeImmutable('now'),
            );
            foreach ($requests as $request) {
                $this->notifications->tripReadyToAssign($request, $data->handledBy);
            }

            return $requests;
        });
        foreach ($requests as $request) {
            $this->realtime->tripRequest('trip-request.approved', $request);
        }

        return $requests;
    }
}
