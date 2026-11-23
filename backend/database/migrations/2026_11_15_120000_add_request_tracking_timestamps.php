<?php

declare(strict_types=1);

use App\Infrastructure\Persistence\Eloquent\Support\BackfillRequestTrackingTimestamps;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('trip_requests', function (Blueprint $table): void {
            $table->timestamp('approved_at')->nullable();
        });

        Schema::table('trips', function (Blueprint $table): void {
            $table->timestamp('assigned_at')->nullable();
        });

        BackfillRequestTrackingTimestamps::run();
    }

    public function down(): void
    {
        Schema::table('trip_requests', function (Blueprint $table): void {
            $table->dropColumn('approved_at');
        });

        Schema::table('trips', function (Blueprint $table): void {
            $table->dropColumn('assigned_at');
        });
    }
};
