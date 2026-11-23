<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trip_requests', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('employee_id')->constrained('users')->cascadeOnDelete();
            $table->string('requester_role');
            $table->foreignUuid('pickup_place_id')->nullable()->constrained('places')->nullOnDelete();
            $table->string('pickup_name');
            $table->decimal('pickup_lat', 10, 7)->nullable();
            $table->decimal('pickup_lng', 10, 7)->nullable();
            $table->string('pickup_address')->nullable();
            $table->foreignUuid('destination_place_id')->nullable()->constrained('places')->nullOnDelete();
            $table->string('destination_name');
            $table->decimal('destination_lat', 10, 7)->nullable();
            $table->decimal('destination_lng', 10, 7)->nullable();
            $table->string('destination_address')->nullable();
            $table->timestamp('requested_at');
            $table->string('notes')->default('');
            $table->string('status');
            $table->foreignUuid('trip_id')->nullable()->constrained('trips')->nullOnDelete();
            $table->string('rejection_reason')->nullable();
            $table->foreignUuid('handled_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('handled_at')->nullable();
            $table->boolean('auto_approved')->default(false);
            $table->uuid('suggested_group_id')->nullable();
            $table->timestamps();

            $table->index(['employee_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trip_requests');
    }
};
