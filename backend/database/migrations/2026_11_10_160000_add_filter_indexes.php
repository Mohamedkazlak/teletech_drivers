<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('trips', function (Blueprint $table): void {
            $table->index('scheduled_at');
            $table->index('finished_at');
            $table->index('confirmation_status');
            $table->index('confirmation_requested_at');
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->index('role');
            $table->index('availability_status');
            $table->index('deleted_at');
        });
    }

    public function down(): void
    {
        Schema::table('trips', function (Blueprint $table): void {
            $table->dropIndex(['scheduled_at']);
            $table->dropIndex(['finished_at']);
            $table->dropIndex(['confirmation_status']);
            $table->dropIndex(['confirmation_requested_at']);
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->dropIndex(['role']);
            $table->dropIndex(['availability_status']);
            $table->dropIndex(['deleted_at']);
        });
    }
};
