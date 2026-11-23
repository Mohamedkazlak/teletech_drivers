<?php

declare(strict_types=1);

namespace App\Application\Trips\Actions;

use App\Application\Realtime\RealtimePublisher;
use App\Domain\Repositories\TripRepositoryInterface;
use DateTimeImmutable;

final class AutoConfirmStaleTripsAction
{
    public function __construct(
        private readonly TripRepositoryInterface $trips,
        private readonly RealtimePublisher $realtime,
    ) {}

    public function execute(DateTimeImmutable $now): int
    {
        $ids = $this->trips->markPendingConfirmationsUnconfirmed($now->modify('-24 hours'));
        foreach ($ids as $id) {
            $trip = $this->trips->findById($id);
            if ($trip === null) {
                continue;
            }
            $this->realtime->trip(
                'trip.confirmed',
                $trip,
                $trip->confirmationStatus?->value ?? 'unconfirmed',
            );
        }

        return count($ids);
    }
}
