<?php

declare(strict_types=1);

namespace App\Domain\Enums;

/**
 * Requester-facing lifecycle. Derived, never stored.
 */
enum RequestTrackingStage: string
{
    case Submitted = 'submitted';
    case Approved = 'approved';
    case Rejected = 'rejected';
    case DriverAssigned = 'driver_assigned';
    case InProgress = 'in_progress';
    case Finished = 'finished';
    case AwaitingConfirmation = 'awaiting_confirmation';
    case Confirmed = 'confirmed';
    case Unconfirmed = 'unconfirmed';
    case Cancelled = 'cancelled';
}
