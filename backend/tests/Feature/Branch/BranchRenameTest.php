<?php

declare(strict_types=1);

namespace Tests\Feature\Branch;

use App\Domain\Enums\Branch;
use App\Models\Place;
use App\Models\User;
use Database\Seeders\DevSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

final class BranchRenameTest extends TestCase
{
    use RefreshDatabase;

    public function test_migration_rewrites_legacy_branch_values_and_dev_place_names(): void
    {
        $headquarters = User::factory()->create();
        $villa = User::factory()->create();
        DB::table('users')->where('id', $headquarters->id)->update(['branch' => 'headquarters']);
        DB::table('users')->where('id', $villa->id)->update(['branch' => 'villa']);

        $oldHq = Place::factory()->create([
            'name_en' => 'TeleTech Headquarters',
            'is_headquarters' => true,
        ]);
        $oldVilla = Place::factory()->create([
            'name_en' => 'TeleTech Villa',
            'is_headquarters' => false,
        ]);

        $migration = require database_path('migrations/2026_11_04_160000_rename_user_branch_values_and_dev_places.php');
        $migration->up();

        $this->assertSame(
            Branch::CompanyHeadquarters,
            User::query()->findOrFail($headquarters->id)->branch,
        );
        $this->assertSame(
            Branch::NewHeadquarters,
            User::query()->findOrFail($villa->id)->branch,
        );

        $oldHq->refresh();
        $oldVilla->refresh();
        $this->assertSame('TeleTech Company Headquarters', $oldHq->name_en);
        $this->assertTrue($oldHq->is_headquarters);
        $this->assertSame('TeleTech New Headquarters', $oldVilla->name_en);
        $this->assertFalse($oldVilla->is_headquarters);
    }

    public function test_dev_seeder_uses_renamed_places_without_changing_headquarters_flag(): void
    {
        $this->seed(DevSeeder::class);

        $company = Place::query()->where('name_en', 'TeleTech Company Headquarters')->firstOrFail();
        $newer = Place::query()->where('name_en', 'TeleTech New Headquarters')->firstOrFail();

        $this->assertTrue($company->is_headquarters);
        $this->assertFalse($newer->is_headquarters);
        $this->assertSame(
            Branch::CompanyHeadquarters,
            User::query()->where('email', 'employee1@teletech.local')->firstOrFail()->branch,
        );
        $this->assertSame(
            Branch::NewHeadquarters,
            User::query()->where('email', 'driver2@teletech.local')->firstOrFail()->branch,
        );
    }
}
