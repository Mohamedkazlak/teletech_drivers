<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum CreatedTripListBucket: string
{
    case Active = 'active';
    case Completed = 'completed';
    case Cancelled = 'cancelled';

    /**
     * @return list<TripStatus>
     */
    public function statuses(): array
    {
        return match ($this) {
            self::Active => [
                TripStatus::Unassigned,
                TripStatus::Assigned,
                TripStatus::Going,
                TripStatus::AtDestination,
                TripStatus::Returning,
            ],
            self::Completed => [TripStatus::Completed],
            self::Cancelled => [TripStatus::Cancelled],
        };
    }
}
