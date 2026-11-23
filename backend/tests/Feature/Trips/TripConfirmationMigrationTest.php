<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripConfirmationMigrationTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_trips_table_has_nullable_confirmation_columns(): void
    {
        $this->assertTrue(Schema::hasColumns('trips', [
            'confirmation_status',
            'confirmation_requested_at',
            'confirmed_at',
            'confirmed_by',
            'driver_showed_up',
            'confirmation_note',
        ]));

        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $trip = Trip::factory()->create([
            'created_by' => $creator->id,
            'status' => TripStatus::Assigned,
        ]);

        $trip->refresh();
        $this->assertNull($trip->confirmation_status);
        $this->assertNull($trip->confirmation_requested_at);
        $this->assertNull($trip->confirmed_at);
        $this->assertNull($trip->confirmed_by);
        $this->assertNull($trip->driver_showed_up);
        $this->assertNull($trip->confirmation_note);
    }

    public function test_backfill_marks_existing_completed_trips_unconfirmed(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $completed = Trip::factory()->create([
            'created_by' => $creator->id,
            'status' => TripStatus::Completed,
            'confirmation_status' => null,
        ]);
        $going = Trip::factory()->create([
            'created_by' => $creator->id,
            'status' => TripStatus::Going,
            'confirmation_status' => null,
        ]);

        DB::table('trips')
            ->where('status', 'completed')
            ->update(['confirmation_status' => 'unconfirmed']);

        $this->assertSame(
            TripConfirmationStatus::Unconfirmed,
            $completed->fresh()->confirmation_status,
        );
        $this->assertNull($going->fresh()->confirmation_status);

        $migration = file_get_contents(
            database_path('migrations/2026_11_04_170000_add_trip_confirmation_to_trips.php'),
        );
        $this->assertIsString($migration);
        $this->assertStringContainsString("where('status', 'completed')", $migration);
        $this->assertStringContainsString("'confirmation_status' => 'unconfirmed'", $migration);
    }

    public function test_confirmed_by_is_nulled_when_the_user_is_deleted(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $confirmer = User::factory()->employee()->create();
        $trip = Trip::factory()->create([
            'created_by' => $creator->id,
            'status' => TripStatus::Completed,
            'confirmation_status' => TripConfirmationStatus::Confirmed,
            'confirmed_by' => $confirmer->id,
            'confirmed_at' => now(),
            'driver_showed_up' => true,
        ]);

        $confirmer->forceDelete();

        $fresh = $trip->fresh();
        $this->assertNull($fresh->confirmed_by);
        $this->assertSame(TripConfirmationStatus::Confirmed, $fresh->confirmation_status);
        $this->assertTrue($fresh->driver_showed_up);
    }
}
