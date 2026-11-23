<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum AttendanceSource: string
{
    case Scan = 'scan';
    case Admin = 'admin';
}
