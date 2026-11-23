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
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripConfirmationResourceTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_trip_block_is_present_on_show_mine_and_index_when_linked(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $driver->name_en = 'Nour Driver';
        $driver->name_ar = 'نور';
        $driver->save();

        $unlinked = $this->createApprovedUnlinkedRequest($employee);
        $linked = $this->linked($employee, $driver, TripStatus::Completed, TripConfirmationStatus::Pending, false);

        Sanctum::actingAs($employee);

        $this->getJson('/api/trip-requests/'.$unlinked->id)
            ->assertOk()
            ->assertJsonPath('trip_id', null)
            ->assertJsonPath('trip', null);

        $this->getJson('/api/trip-requests/'.$linked->id)
            ->assertOk()
            ->assertJsonPath('trip.id', $linked->trip_id)
            ->assertJsonPath('trip.status', 'completed')
            ->assertJsonPath('trip.driver_name_en', 'Nour Driver')
            ->assertJsonPath('trip.driver_name_ar', 'نور')
            ->assertJsonPath('trip.confirmation_status', 'pending')
            ->assertJsonPath('trip.driver_showed_up', false);

        $mine = collect($this->getJson('/api/trip-requests/mine')->assertOk()->json('data'));
        $this->assertNull($mine->firstWhere('id', $unlinked->id)['trip']);
        $mineLinked = $mine->firstWhere('id', $linked->id)['trip'];
        $this->assertSame($linked->trip_id, $mineLinked['id']);
        $this->assertSame('pending', $mineLinked['confirmation_status']);
        $this->assertFalse($mineLinked['driver_showed_up']);
        $this->assertSame('Nour Driver', $mineLinked['driver_name_en']);

        $this->actingAsRole(UserRole::CompanyAdmin);
        $index = collect($this->getJson('/api/trip-requests')->assertOk()->json('data'));
        $indexed = $index->firstWhere('id', $linked->id)['trip'];
        $this->assertSame($linked->trip_id, $indexed['id']);
        $this->assertSame('completed', $indexed['status']);
        $this->assertSame('نور', $indexed['driver_name_ar']);
        $this->assertNull($index->firstWhere('id', $unlinked->id)['trip']);

        Sanctum::actingAs($employee);
        $this->getJson('/api/trips')->assertForbidden();
        $this->getJson('/api/trips/'.$linked->trip_id)->assertForbidden();
    }

    public function test_trip_resource_includes_confirmation_fields(): void
    {
        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $trip = Trip::factory()->create([
            'created_by' => $admin->id,
            'status' => TripStatus::Completed,
            'confirmation_status' => TripConfirmationStatus::Confirmed,
            'confirmation_requested_at' => '2026-11-04 10:00:00',
            'confirmed_at' => '2026-11-04 11:00:00',
            'confirmed_by' => $admin->id,
            'driver_showed_up' => false,
            'confirmation_note' => 'did not arrive',
        ]);

        Sanctum::actingAs($admin);
        $this->getJson('/api/trips/'.$trip->id)
            ->assertOk()
            ->assertJsonPath('confirmation_status', 'confirmed')
            ->assertJsonPath('confirmation_requested_at', '2026-11-04T10:00:00+00:00')
            ->assertJsonPath('confirmed_at', '2026-11-04T11:00:00+00:00')
            ->assertJsonPath('driver_showed_up', false)
            ->assertJsonPath('confirmation_note', 'did not arrive');

        $this->actingAsRole(UserRole::CompanyAdmin);
        $summary = collect($this->getJson('/api/trips')->assertOk()->json('data'))->firstWhere('id', $trip->id);
        $this->assertSame('confirmed', $summary['confirmation_status']);
        $this->assertFalse($summary['driver_showed_up']);
        $this->assertSame('did not arrive', $summary['confirmation_note']);
        $this->assertArrayNotHasKey('going_route', $summary);

        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/trips/'.$trip->id)
            ->assertForbidden();
    }

    public function test_mine_awaiting_confirmation_filter(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $other = $this->createUserWithRole(UserRole::Employee);
        $driver = $this->createUserWithRole(UserRole::Driver);

        $pending = $this->linked($employee, $driver, TripStatus::Completed, TripConfirmationStatus::Pending, null);
        $confirmed = $this->linked($employee, $driver, TripStatus::Completed, TripConfirmationStatus::Confirmed, true);
        $unconfirmed = $this->linked($employee, $driver, TripStatus::Completed, TripConfirmationStatus::Unconfirmed, false);
        $going = $this->linked($employee, $driver, TripStatus::Going, TripConfirmationStatus::Pending, null);
        $open = $this->createApprovedUnlinkedRequest($employee);
        $someoneElse = $this->linked($other, $driver, TripStatus::Completed, TripConfirmationStatus::Pending, null);

        Sanctum::actingAs($employee);

        $ids = collect($this->getJson('/api/trip-requests/mine?awaiting_confirmation=true')
            ->assertOk()
            ->json('data'))->pluck('id')->all();

        $this->assertSame([$pending->id], $ids);
        $this->assertNotContains($confirmed->id, $ids);
        $this->assertNotContains($unconfirmed->id, $ids);
        $this->assertNotContains($going->id, $ids);
        $this->assertNotContains($open->id, $ids);
        $this->assertNotContains($someoneElse->id, $ids);

        $all = collect($this->getJson('/api/trip-requests/mine?awaiting_confirmation=false')
            ->assertOk()
            ->json('data'))->pluck('id');
        $this->assertTrue($all->contains($pending->id));
        $this->assertTrue($all->contains($confirmed->id));
        $this->assertTrue($all->contains($open->id));
        $this->assertFalse($all->contains($someoneElse->id));

        $this->getJson('/api/trip-requests/mine?awaiting_confirmation=maybe')
            ->assertJsonValidationErrors(['awaiting_confirmation']);
    }

    private function linked(
        User $employee,
        User $driver,
        TripStatus $status,
        ?TripConfirmationStatus $confirmation,
        ?bool $showedUp,
    ): TripRequest {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $trip = Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => $driver->id,
            'status' => $status,
            'confirmation_status' => $confirmation,
            'confirmation_requested_at' => $confirmation === null ? null : now(),
            'driver_showed_up' => $showedUp,
        ]);

        return TripRequest::factory()->approved()->create([
            'employee_id' => $employee->id,
            'requester_role' => UserRole::Employee,
            'trip_id' => $trip->id,
        ]);
    }
}
