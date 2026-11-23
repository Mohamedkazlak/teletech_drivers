<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $driver = Schema::getConnection()->getDriverName();

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE trip_requests ALTER COLUMN rejection_reason TYPE VARCHAR(500)');
        } elseif ($driver === 'mysql') {
            DB::statement('ALTER TABLE trip_requests MODIFY rejection_reason VARCHAR(500) NULL');
        }

        Schema::table('trip_requests', function (Blueprint $table): void {
            $table->index(['status', 'requested_at']);
            $table->index('trip_id');
            $table->index('suggested_group_id');
        });
    }

    public function down(): void
    {
        Schema::table('trip_requests', function (Blueprint $table): void {
            $table->dropIndex(['trip_requests_status_requested_at_index']);
            $table->dropIndex(['trip_requests_trip_id_index']);
            $table->dropIndex(['trip_requests_suggested_group_id_index']);
        });

        $driver = Schema::getConnection()->getDriverName();

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE trip_requests ALTER COLUMN rejection_reason TYPE VARCHAR(255)');
        } elseif ($driver === 'mysql') {
            DB::statement('ALTER TABLE trip_requests MODIFY rejection_reason VARCHAR(255) NULL');
        }
    }
};
