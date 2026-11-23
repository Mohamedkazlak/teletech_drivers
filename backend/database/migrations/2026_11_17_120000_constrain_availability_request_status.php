<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * requested_status is a string. Allow the request-only finished_today value.
 * users.availability_status stays available|unavailable and is not constrained here.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement(
            "ALTER TABLE availability_requests ADD CONSTRAINT availability_requests_requested_status_check CHECK (requested_status IN ('available', 'unavailable', 'finished_today'))",
        );
    }

    public function down(): void
    {
        DB::statement(
            'ALTER TABLE availability_requests DROP CONSTRAINT availability_requests_requested_status_check',
        );
    }
};
