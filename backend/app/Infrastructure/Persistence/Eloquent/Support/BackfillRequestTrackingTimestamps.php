<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent\Support;

use Illuminate\Support\Facades\DB;

/**
 * Fills approved_at and assigned_at from the timestamps that already existed.
 */
final class BackfillRequestTrackingTimestamps
{
    public static function run(): void
    {
        DB::table('trip_requests')
            ->whereNull('approved_at')
            ->where(function ($query): void {
                $query->where('status', 'approved')
                    ->orWhere('auto_approved', true);
            })
            ->update([
                'approved_at' => DB::raw('COALESCE(handled_at, created_at)'),
            ]);

        // Trips still waiting on a driver keep updated_at (the assignment write).
        // Trips that already started have no assignment clock, so going_started_at
        // is the earliest stored moment we know a driver was on the trip.
        DB::table('trips')
            ->whereNotNull('driver_id')
            ->whereNull('assigned_at')
            ->update([
                'assigned_at' => DB::raw(
                    "CASE WHEN status = 'assigned' OR going_started_at IS NULL THEN updated_at ELSE going_started_at END",
                ),
            ]);
    }
}
