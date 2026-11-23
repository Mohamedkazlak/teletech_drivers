<?php

declare(strict_types=1);

namespace App\Domain\Enums;

/**
 * Driver-list and live-map filter. Checked in means an open attendance
 * row for today (checked out is still null), whether or not a trip is active.
 */
enum DriverAttendanceFilter: string
{
    case CheckedIn = 'checked_in';
    case NotCheckedIn = 'not_checked_in';
}
