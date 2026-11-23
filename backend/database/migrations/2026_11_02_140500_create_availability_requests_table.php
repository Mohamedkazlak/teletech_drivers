<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('availability_requests', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('driver_id')->constrained('users')->cascadeOnDelete();
            $table->string('requested_status');
            $table->string('state')->default('pending');
            $table->timestamp('requested_at')->nullable();
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->float('accuracy')->nullable();
            $table->timestamp('position_timestamp')->nullable();
            $table->boolean('is_mocked')->default(false);
            $table->unsignedBigInteger('distance_from_hq_m')->nullable();
            $table->foreignUuid('hq_place_id')->nullable()->constrained('places')->nullOnDelete();
            $table->foreignUuid('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->string('rejection_reason', 500)->nullable();
            $table->timestamps();

            $table->index(['state', 'requested_at']);
            $table->index('driver_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('availability_requests');
    }
};
