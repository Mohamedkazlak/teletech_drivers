<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum TripRequestListBucket: string
{
    case Active = 'active';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
}
