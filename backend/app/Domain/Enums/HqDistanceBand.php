<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum HqDistanceBand: string
{
    case Near = 'near';
    case Medium = 'medium';
    case Far = 'far';
    case Unknown = 'unknown';
}
