<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum TripRequestStage: string
{
    case NeedsDriver = 'needs_driver';
    case Assigned = 'assigned';
}
