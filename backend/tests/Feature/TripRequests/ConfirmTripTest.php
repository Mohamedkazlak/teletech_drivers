<?php

declare(strict_types=1);

namespace Tests\Feature\TripRequests;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\TripRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class ConfirmTripTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_requester_confirms_a_pending_completed_trip(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $driver = $this->namedDriver();
        $request = $this->linkedRequest($employee, TripStatus::Completed, TripConfirmationStatus::Pending, $driver);
        $note = str_repeat('n', 500);

        try {
            Carbon::setTestNow('2026-11-04 16:30:00');
            Sanctum::actingAs($employee);

            $response = $this->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
                'driver_showed_up' => false,
                'note' => $note,
            ])->assertOk();
        } finally {
            Carbon::setTestNow();
        }

        $response
            ->assertJsonPath('id', $request->id)
            ->assertJsonPath('trip_id', $request->trip_id)
            ->assertJsonPath('trip.id', $request->trip_id)
            ->assertJsonPath('trip.status', 'completed')
            ->assertJsonPath('trip.driver_name_en', 'Karim Driver')
            ->assertJsonPath('trip.driver_name_ar', 'كريم')
            ->assertJsonPath('trip.confirmation_status', 'confirmed')
            ->assertJsonPath('trip.driver_showed_up', false);

        $this->assertSame(
            ['id', 'status', 'driver_name_en', 'driver_name_ar', 'confirmation_status', 'driver_showed_up'],
            array_keys($response->json('trip')),
        );

        $trip = Trip::query()->findOrFail($request->trip_id);
        $this->assertSame(TripStatus::Completed, $trip->status);
        $this->assertSame(TripConfirmationStatus::Confirmed, $trip->confirmation_status);
        $this->assertTrue($trip->confirmed_at?->equalTo(Carbon::parse('2026-11-04 16:30:00')));
        $this->assertSame($employee->id, $trip->confirmed_by);
        $this->assertFalse($trip->driver_showed_up);
        $this->assertSame($note, $trip->confirmation_note);

        Sanctum::actingAs($employee);
        $this->getJson('/api/trips')->assertForbidden();
        $this->getJson('/api/trips/'.$trip->id)->assertForbidden();
    }

    public function test_note_is_optional(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $request = $this->linkedRequest($employee, TripStatus::Completed, TripConfirmationStatus::Pending);

        Sanctum::actingAs($employee);
        $this->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
            'driver_showed_up' => true,
        ])->assertOk()
            ->assertJsonPath('trip.driver_showed_up', true)
            ->assertJsonPath('trip.confirmation_status', 'confirmed');

        $this->assertNull(Trip::query()->findOrFail($request->trip_id)->confirmation_note);
    }

    public function test_only_the_requester_may_confirm(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $request = $this->linkedRequest($employee, TripStatus::Completed, TripConfirmationStatus::Pending);

        $this->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
            'driver_showed_up' => true,
        ])->assertUnauthorized();

        foreach ([
            UserRole::Employee,
            UserRole::Driver,
            UserRole::DriversAdmin,
            UserRole::CompanyAdmin,
            UserRole::Admin,
        ] as $role) {
            $this->actingAsRole($role)
                ->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
                    'driver_showed_up' => true,
                ])
                ->assertForbidden();
        }

        $this->assertSame(
            TripConfirmationStatus::Pending,
            Trip::query()->findOrFail($request->trip_id)->confirmation_status,
        );
    }

    public function test_request_must_be_linked_to_a_completed_pending_trip(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        Sanctum::actingAs($employee);

        $unlinked = $this->createApprovedUnlinkedRequest($employee);
        $this->postJson('/api/trip-requests/'.$unlinked->id.'/confirm-trip', [
            'driver_showed_up' => true,
        ])->assertStatus(409)
            ->assertJsonPath('message', 'Trip request is not linked to a completed trip awaiting confirmation.');

        $going = $this->linkedRequest($employee, TripStatus::Going, TripConfirmationStatus::Pending);
        $this->postJson('/api/trip-requests/'.$going->id.'/confirm-trip', [
            'driver_showed_up' => true,
        ])->assertStatus(409)
            ->assertJsonPath('message', 'Trip request is not linked to a completed trip awaiting confirmation.');

        $completedWithoutConfirmation = $this->linkedRequest($employee, TripStatus::Completed, null);
        $this->postJson('/api/trip-requests/'.$completedWithoutConfirmation->id.'/confirm-trip', [
            'driver_showed_up' => true,
        ])->assertStatus(409)
            ->assertJsonPath('message', 'Trip request is not linked to a completed trip awaiting confirmation.');
    }

    public function test_already_confirmed_or_unconfirmed_returns_409(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        Sanctum::actingAs($employee);

        $confirmed = $this->linkedRequest($employee, TripStatus::Completed, TripConfirmationStatus::Confirmed);
        $confirmed->trip->driver_showed_up = true;
        $confirmed->trip->confirmation_note = 'kept';
        $confirmed->trip->save();

        $this->postJson('/api/trip-requests/'.$confirmed->id.'/confirm-trip', [
            'driver_showed_up' => false,
            'note' => 'overwrite',
        ])->assertStatus(409)
            ->assertJsonPath('message', 'This trip has already been confirmed.');

        $confirmed->trip->refresh();
        $this->assertTrue($confirmed->trip->driver_showed_up);
        $this->assertSame('kept', $confirmed->trip->confirmation_note);

        $unconfirmed = $this->linkedRequest($employee, TripStatus::Completed, TripConfirmationStatus::Unconfirmed);
        $this->postJson('/api/trip-requests/'.$unconfirmed->id.'/confirm-trip', [
            'driver_showed_up' => true,
        ])->assertStatus(409)
            ->assertJsonPath('message', 'This trip is already unconfirmed.');
    }

    public function test_first_requester_to_confirm_wins(): void
    {
        $first = $this->createUserWithRole(UserRole::Employee);
        $second = $this->createUserWithRole(UserRole::Employee);
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $trip = Trip::factory()->create([
            'created_by' => $creator->id,
            'status' => TripStatus::Completed,
            'confirmation_status' => TripConfirmationStatus::Pending,
            'confirmation_requested_at' => now(),
        ]);

        $firstRequest = TripRequest::factory()->approved()->create([
            'employee_id' => $first->id,
            'requester_role' => UserRole::Employee,
            'trip_id' => $trip->id,
        ]);
        $secondRequest = TripRequest::factory()->approved()->create([
            'employee_id' => $second->id,
            'requester_role' => UserRole::Employee,
            'trip_id' => $trip->id,
        ]);

        Sanctum::actingAs($first);
        $this->postJson('/api/trip-requests/'.$firstRequest->id.'/confirm-trip', [
            'driver_showed_up' => false,
            'note' => 'no show',
        ])->assertOk()
            ->assertJsonPath('trip.confirmation_status', 'confirmed')
            ->assertJsonPath('trip.driver_showed_up', false);

        Sanctum::actingAs($second);
        $this->postJson('/api/trip-requests/'.$secondRequest->id.'/confirm-trip', [
            'driver_showed_up' => true,
            'note' => 'too late',
        ])->assertStatus(409)
            ->assertJsonPath('message', 'This trip has already been confirmed.');

        $trip->refresh();
        $this->assertSame($first->id, $trip->confirmed_by);
        $this->assertFalse($trip->driver_showed_up);
        $this->assertSame('no show', $trip->confirmation_note);
    }

    public function test_validation_and_missing_request(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $request = $this->linkedRequest($employee, TripStatus::Completed, TripConfirmationStatus::Pending);
        Sanctum::actingAs($employee);

        $this->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [])
            ->assertJsonValidationErrors(['driver_showed_up']);

        $this->postJson('/api/trip-requests/'.$request->id.'/confirm-trip', [
            'driver_showed_up' => true,
            'note' => str_repeat('x', 501),
        ])->assertJsonValidationErrors(['note']);

        $this->postJson('/api/trip-requests/'.fake()->uuid().'/confirm-trip', [
            'driver_showed_up' => true,
        ])->assertNotFound();
    }

    private function namedDriver(): User
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        $driver->name_en = 'Karim Driver';
        $driver->name_ar = 'كريم';
        $driver->save();

        return $driver;
    }

    private function linkedRequest(
        User $employee,
        TripStatus $status,
        ?TripConfirmationStatus $confirmation,
        ?User $driver = null,
    ): TripRequest {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $trip = Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => $driver?->id,
            'status' => $status,
            'confirmation_status' => $confirmation,
            'confirmation_requested_at' => $confirmation === TripConfirmationStatus::Pending ? now() : null,
        ]);

        return TripRequest::factory()->approved()->create([
            'employee_id' => $employee->id,
            'requester_role' => UserRole::Employee,
            'trip_id' => $trip->id,
        ]);
    }
}
