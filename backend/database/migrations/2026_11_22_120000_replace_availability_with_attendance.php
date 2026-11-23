<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Test data only. Drops the availability queue and stored driver status.
 * Availability is derived from attendance_logs plus active trips.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attendance_logs', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('driver_id')->constrained('users')->cascadeOnDelete();
            $table->date('work_date');
            $table->timestampTz('checked_in_at');
            $table->decimal('check_in_lat', 10, 7)->nullable();
            $table->decimal('check_in_lng', 10, 7)->nullable();
            $table->float('check_in_accuracy_m')->nullable();
            $table->unsignedInteger('check_in_distance_m')->nullable();
            $table->timestampTz('checked_out_at')->nullable();
            $table->decimal('check_out_lat', 10, 7)->nullable();
            $table->decimal('check_out_lng', 10, 7)->nullable();
            $table->float('check_out_accuracy_m')->nullable();
            $table->unsignedInteger('check_out_distance_m')->nullable();
            $table->string('source');
            $table->foreignUuid('adjusted_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('adjustment_reason')->nullable();
            $table->timestamps();

            $table->unique(['driver_id', 'work_date']);
            $table->index('work_date');
        });

        Schema::dropIfExists('availability_requests');

        Schema::table('users', function (Blueprint $table): void {
            $table->dropIndex(['availability_status']);
            $table->dropForeign(['availability_approved_by']);
            $table->dropColumn([
                'availability_status',
                'availability_updated_at',
                'availability_approved_by',
            ]);
        });

        Schema::table('trips', function (Blueprint $table): void {
            $table->dropColumn('driver_availability_before');
        });
    }

    public function down(): void
    {
        Schema::table('trips', function (Blueprint $table): void {
            $table->string('driver_availability_before')->nullable();
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->string('availability_status')->default('unavailable');
            $table->timestamp('availability_updated_at')->nullable();
            $table->uuid('availability_approved_by')->nullable();
            $table->index('availability_status');
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->foreign('availability_approved_by')->references('id')->on('users')->nullOnDelete();
        });

        Schema::dropIfExists('attendance_logs');
    }
};
