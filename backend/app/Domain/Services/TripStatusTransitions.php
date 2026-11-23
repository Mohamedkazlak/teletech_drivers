<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Enums\TripStatus;
use App\Domain\Exceptions\InvalidTripStatusTransitionException;

/**
 * State: allowed trip phase transitions (mirrors Flutter TripPhaseController).
 */
final class TripStatusTransitions
{
    /**
     * @var array<string, list<string>>
     */
    private const ALLOWED = [
        TripStatus::Unassigned->value => [
            TripStatus::Assigned->value,
            TripStatus::Cancelled->value,
        ],
        TripStatus::Assigned->value => [
            TripStatus::Going->value,
            TripStatus::Cancelled->value,
        ],
        TripStatus::Going->value => [
            TripStatus::AtDestination->value,
        ],
        TripStatus::AtDestination->value => [
            TripStatus::Returning->value,
        ],
        TripStatus::Returning->value => [
            TripStatus::Completed->value,
        ],
        TripStatus::Completed->value => [],
        TripStatus::Cancelled->value => [],
    ];

    public function canTransition(TripStatus $from, TripStatus $to): bool
    {
        $allowed = self::ALLOWED[$from->value] ?? [];

        return in_array($to->value, $allowed, true);
    }

    public function assertTransition(TripStatus $from, TripStatus $to): void
    {
        if (! $this->canTransition($from, $to)) {
            throw new InvalidTripStatusTransitionException($from, $to);
        }
    }

    public function canAssign(TripStatus $status): bool
    {
        return $this->canTransition($status, TripStatus::Assigned);
    }

    /**
     * Reassign keeps status assigned; it is not a status transition.
     */
    public function canReassign(TripStatus $status): bool
    {
        return $status === TripStatus::Assigned;
    }

    public function canCancel(TripStatus $status): bool
    {
        return $this->canTransition($status, TripStatus::Cancelled);
    }

    public function canStartTrip(TripStatus $status): bool
    {
        return $this->canTransition($status, TripStatus::Going);
    }

    public function canArriveAtDestination(TripStatus $status): bool
    {
        return $this->canTransition($status, TripStatus::AtDestination);
    }

    public function canStartReturn(TripStatus $status): bool
    {
        return $this->canTransition($status, TripStatus::Returning);
    }

    public function canEndTrip(TripStatus $status): bool
    {
        return $this->canTransition($status, TripStatus::Completed);
    }
}
