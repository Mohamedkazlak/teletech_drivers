<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Services;

use App\Domain\Entities\PlaceSnapshot;
use App\Domain\Exceptions\RequestedAtMustBeFutureException;
use App\Domain\Exceptions\SamePickupAndDestinationException;
use App\Domain\Services\ScheduleTime;
use DateTimeImmutable;

final class TripRequestCreateValidator
{
    public function __construct(private readonly ScheduleTime $schedule) {}

    public function assertValid(
        PlaceSnapshot $pickup,
        PlaceSnapshot $destination,
        DateTimeImmutable $requestedAt,
    ): void {
        if ($this->schedule->isNotFuture($requestedAt)) {
            throw new RequestedAtMustBeFutureException;
        }

        if ($this->samePlace($pickup, $destination)) {
            throw new SamePickupAndDestinationException;
        }
    }

    private function samePlace(PlaceSnapshot $a, PlaceSnapshot $b): bool
    {
        if ($a->placeId !== null && $a->placeId === $b->placeId) {
            return true;
        }

        if ($a->placeId === null && $b->placeId === null
            && $a->lat !== null && $b->lat !== null
            && $a->lng !== null && $b->lng !== null
            && $a->lat === $b->lat
            && $a->lng === $b->lng
            && mb_strtolower($a->name) === mb_strtolower($b->name)
        ) {
            return true;
        }

        return false;
    }
}
