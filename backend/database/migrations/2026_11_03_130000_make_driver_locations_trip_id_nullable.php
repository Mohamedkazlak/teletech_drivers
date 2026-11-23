<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Ensures driver_locations.trip_id is nullable (PUT body allows null trip_id).
 * Safe when the base migration already created it as nullable.
 */
return new class extends Migration
{
    public function up(): void
    {
        $driver = Schema::getConnection()->getDriverName();

        if ($driver === 'sqlite') {
            $this->recreateSqliteNullable();

            return;
        }

        Schema::table('driver_locations', function (Blueprint $table): void {
            $table->dropForeign(['trip_id']);
        });

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE driver_locations ALTER COLUMN trip_id DROP NOT NULL');
        } else {
            DB::statement('ALTER TABLE driver_locations MODIFY trip_id CHAR(36) NULL');
        }

        Schema::table('driver_locations', function (Blueprint $table): void {
            $table->foreign('trip_id')->references('id')->on('trips')->nullOnDelete();
        });
    }

    public function down(): void
    {
        // Non-reversible safely when null trip_ids exist; leave nullable.
    }

    private function recreateSqliteNullable(): void
    {
        // SQLite cannot ALTER nullability; rebuild only if the FK is still NOT NULL.
        $info = DB::select("PRAGMA table_info('driver_locations')");
        $tripIdNotNull = false;
        foreach ($info as $column) {
            if (($column->name ?? null) === 'trip_id' && (int) ($column->notnull ?? 0) === 1) {
                $tripIdNotNull = true;
                break;
            }
        }

        if (! $tripIdNotNull) {
            return;
        }

        Schema::create('driver_locations_tmp', function (Blueprint $table): void {
            $table->foreignUuid('driver_id')->primary()->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('trip_id')->nullable()->constrained('trips')->nullOnDelete();
            $table->decimal('lat', 10, 7);
            $table->decimal('lng', 10, 7);
            $table->float('heading')->default(0);
            $table->float('speed')->default(0);
            $table->float('accuracy')->default(0);
            $table->boolean('is_tracking')->default(false);
            $table->timestamp('updated_at')->nullable();
        });

        $rows = DB::table('driver_locations')->get();
        foreach ($rows as $row) {
            DB::table('driver_locations_tmp')->insert((array) $row);
        }

        Schema::drop('driver_locations');
        Schema::rename('driver_locations_tmp', 'driver_locations');
    }
};
