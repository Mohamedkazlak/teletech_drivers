<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('driver_profiles', function (Blueprint $table) {
            $table->foreignUuid('user_id')->primary()->constrained('users')->cascadeOnDelete();
            $table->string('national_id')->default('');
            $table->string('car_license')->default('');
            $table->string('personal_license')->default('');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('driver_profiles');
    }
};
