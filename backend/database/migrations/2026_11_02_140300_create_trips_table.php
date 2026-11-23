<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trips', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('driver_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('scheduled_at');
            $table->string('status')->default('unassigned');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->string('pickup_summary')->nullable();
            $table->string('destination_summary')->nullable();
            $table->timestamp('going_started_at')->nullable();
            $table->timestamp('going_ended_at')->nullable();
            $table->timestamp('return_started_at')->nullable();
            $table->timestamp('finished_at')->nullable();
            $table->decimal('start_lat', 10, 7)->nullable();
            $table->decimal('start_lng', 10, 7)->nullable();
            $table->unsignedBigInteger('going_distance_m')->nullable();
            $table->unsignedBigInteger('return_distance_m')->nullable();
            $table->unsignedBigInteger('total_distance_m')->nullable();
            $table->text('going_route')->nullable();
            $table->text('return_route')->nullable();
            $table->timestamps();

            $table->index(['status', 'created_at']);
            $table->index('driver_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trips');
    }
};
