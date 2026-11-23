<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum TripStatus: string
{
    case Unassigned = 'unassigned';
    case Assigned = 'assigned';
    case Going = 'going';
    case AtDestination = 'at_destination';
    case Returning = 'returning';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
}
