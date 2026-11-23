<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum TripCreationMode: string
{
    case OnePerRequest = 'one_per_request';
    case Grouped = 'grouped';
}
