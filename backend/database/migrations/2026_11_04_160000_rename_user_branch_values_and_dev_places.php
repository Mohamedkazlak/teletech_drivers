<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * users.branch is a string, so this is a value rewrite (portable on PostgreSQL).
 * places.is_headquarters is the distance-origin flag and is left unchanged.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::table('users')->where('branch', 'headquarters')->update([
            'branch' => 'company_headquarters',
        ]);
        DB::table('users')->where('branch', 'villa')->update([
            'branch' => 'new_headquarters',
        ]);

        DB::table('places')->where('name_en', 'TeleTech Headquarters')->update([
            'name_en' => 'TeleTech Company Headquarters',
        ]);
        DB::table('places')->where('name_en', 'TeleTech Villa')->update([
            'name_en' => 'TeleTech New Headquarters',
        ]);
    }

    public function down(): void
    {
        DB::table('users')->where('branch', 'company_headquarters')->update([
            'branch' => 'headquarters',
        ]);
        DB::table('users')->where('branch', 'new_headquarters')->update([
            'branch' => 'villa',
        ]);

        DB::table('places')->where('name_en', 'TeleTech Company Headquarters')->update([
            'name_en' => 'TeleTech Headquarters',
        ]);
        DB::table('places')->where('name_en', 'TeleTech New Headquarters')->update([
            'name_en' => 'TeleTech Villa',
        ]);
    }
};
