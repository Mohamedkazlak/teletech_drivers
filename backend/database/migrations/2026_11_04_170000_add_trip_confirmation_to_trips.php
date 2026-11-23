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
        Schema::table('trips', function (Blueprint $table): void {
            $table->string('confirmation_status')->nullable();
            $table->timestamp('confirmation_requested_at')->nullable();
            $table->timestamp('confirmed_at')->nullable();
            $table->foreignUuid('confirmed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->boolean('driver_showed_up')->nullable();
            $table->string('confirmation_note', 500)->nullable();
        });

        DB::table('trips')
            ->where('status', 'completed')
            ->update(['confirmation_status' => 'unconfirmed']);
    }

    public function down(): void
    {
        Schema::table('trips', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('confirmed_by');
        });

        Schema::table('trips', function (Blueprint $table): void {
            $table->dropColumn([
                'confirmation_status',
                'confirmation_requested_at',
                'confirmed_at',
                'driver_showed_up',
                'confirmation_note',
            ]);
        });
    }
};
