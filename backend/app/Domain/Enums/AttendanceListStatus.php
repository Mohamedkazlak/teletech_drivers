<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum AttendanceListStatus: string
{
    case Present = 'present';
    case Absent = 'absent';
    case CheckedIn = 'checked_in';
    case CheckedOut = 'checked_out';
}
