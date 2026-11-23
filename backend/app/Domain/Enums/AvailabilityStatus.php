<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum AvailabilityStatus: string
{
    case Available = 'available';
    case Unavailable = 'unavailable';

    /**
     * Request-only. Never stored on users.availability_status.
     * "Finished for today" is computed from approved requests.
     */
    case FinishedToday = 'finished_today';
}
