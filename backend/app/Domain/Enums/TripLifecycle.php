<?php

declare(strict_types=1);

namespace App\Domain\Enums;

/**
 * Company-admin trip list filter. One lifecycle bucket, not the fine-grained
 * status and the overlapping stage at the same time.
 */
enum TripLifecycle: string
{
    case Upcoming = 'upcoming';
    case InProgress = 'in_progress';
    case Completed = 'completed';
    case Cancelled = 'cancelled';

    /**
     * @return list<TripStatus>
     */
    public function statuses(): array
    {
        return match ($this) {
            self::Upcoming => [TripStatus::Unassigned, TripStatus::Assigned],
            self::InProgress => [
                TripStatus::Going,
                TripStatus::AtDestination,
                TripStatus::Returning,
            ],
            self::Completed => [TripStatus::Completed],
            self::Cancelled => [TripStatus::Cancelled],
        };
    }
}
