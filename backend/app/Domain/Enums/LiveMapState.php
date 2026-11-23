<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum LiveMapState: string
{
    case OnTrip = 'on_trip';
    case Available = 'available';
    case Unavailable = 'unavailable';
}
