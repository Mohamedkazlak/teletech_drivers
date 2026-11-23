<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum TripConfirmationStatus: string
{
    case Pending = 'pending';
    case Confirmed = 'confirmed';
    case Unconfirmed = 'unconfirmed';
}
