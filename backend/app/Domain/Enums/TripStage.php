<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum TripStage: string
{
    case Unassigned = 'unassigned';
    case Assigned = 'assigned';
    case InProgress = 'in_progress';
    case AwaitingReport = 'awaiting_report';
    case Completed = 'completed';
    case Cancelled = 'cancelled';

    /**
     * @return list<TripStatus>
     */
    public function statuses(): array
    {
        return match ($this) {
            self::Unassigned => [TripStatus::Unassigned],
            self::Assigned => [TripStatus::Assigned],
            self::InProgress => [
                TripStatus::Going,
                TripStatus::AtDestination,
                TripStatus::Returning,
            ],
            self::AwaitingReport, self::Completed => [TripStatus::Completed],
            self::Cancelled => [TripStatus::Cancelled],
        };
    }

    /**
     * Confirmation statuses that further narrow {@see statuses()}.
     * Null means this stage does not constrain confirmation.
     *
     * @return list<TripConfirmationStatus>|null
     */
    public function confirmationStatuses(): ?array
    {
        return match ($this) {
            self::AwaitingReport => [TripConfirmationStatus::Pending],
            self::Completed => [
                TripConfirmationStatus::Confirmed,
                TripConfirmationStatus::Unconfirmed,
            ],
            default => null,
        };
    }
}
