<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum TripRequestStatus: string
{
    case Pending = 'pending';
    case Approved = 'approved';
    case Rejected = 'rejected';
    case Cancelled = 'cancelled';
}
