<?php

declare(strict_types=1);

namespace Tests\Feature\TripRequests;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Infrastructure\Persistence\Eloquent\Support\BackfillRequestTrackingTimestamps;
use App\Models\Trip;
use App\Models\TripRequest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class RequestTrackingTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    private const POLYLINE = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

    public function test_employee_can_follow_every_stage_and_driver_stays_hidden_until_assigned(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $driver->forceFill([
            'name_en' => 'Nader Ali',
            'name_ar' => 'نادر علي',
            'phone' => '01055551212',
        ])->save();
        $driver->driverProfile()->update(['car_license' => 'PLATE-9']);

        Sanctum::actingAs($employee);
        $created = $this->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated()
            ->assertJsonPath('tracking.stage', 'submitted')
            ->assertJsonPath('tracking.driver', null)
            ->assertJsonPath('tracking.vehicle', null)
            ->assertJsonPath('tracking.rejection_reason', null);

        $requestId = (string) $created->json('id');
        $this->assertArrayNotHasKey('notes', $created->json('tracking'));
        $this->assertSame('employee', $this->timeline($created->json('tracking'), 'submitted')['actor_role']);
        $this->assertNull($this->timeline($created->json('tracking'), 'approved')['reached_at']);

        Sanctum::actingAs($companyAdmin);
        $approved = $this->postJson('/api/trip-requests/'.$requestId.'/approve')
            ->assertOk()
            ->assertJsonPath('tracking.stage', 'approved');
        $this->assertNotNull($this->timeline($approved->json('tracking'), 'approved')['reached_at']);
        $this->assertSame('company_admin', $this->timeline($approved->json('tracking'), 'approved')['actor_role']);
        $this->assertNotNull(TripRequest::query()->findOrFail($requestId)->approved_at);

        Sanctum::actingAs($driversAdmin);
        $tripId = (string) $this->postJson('/api/trips/from-requests', [
            'mode' => 'one_per_request',
            'request_ids' => [$requestId],
        ])->assertCreated()->json('data.0.id');

        Sanctum::actingAs($employee);
        $waiting = $this->getJson('/api/trip-requests/'.$requestId)->assertOk();
        $waiting->assertJsonPath('tracking.stage', 'approved')
            ->assertJsonPath('tracking.driver', null)
            ->assertJsonPath('tracking.vehicle', null);
        $this->assertNotNull($waiting->json('tracking.scheduled_at'));
        $this->assertStringNotContainsString('01055551212', $waiting->getContent());
        $this->assertStringNotContainsString('PLATE-9', $waiting->getContent());

        Sanctum::actingAs($driversAdmin);
        $this->postJson('/api/trips/'.$tripId.'/assign', ['driver_id' => $driver->id])
            ->assertOk();
        $this->assertNotNull(Trip::query()->findOrFail($tripId)->assigned_at);

        Sanctum::actingAs($employee);
        $assigned = $this->getJson('/api/trip-requests/'.$requestId)
            ->assertOk()
            ->assertJsonPath('tracking.stage', 'driver_assigned')
            ->assertJsonPath('tracking.driver.name_en', 'Nader Ali')
            ->assertJsonPath('tracking.driver.phone', '01055551212')
            ->assertJsonPath('tracking.vehicle.car_license', 'PLATE-9');
        $this->assertNotNull($this->timeline($assigned->json('tracking'), 'driver_assigned')['reached_at']);
        $this->assertSame('drivers_admin', $this->timeline($assigned->json('tracking'), 'driver_assigned')['actor_role']);

        $mine = collect($this->getJson('/api/my-trips')->assertOk()->json('data'))->firstWhere('id', $tripId);
        $this->assertIsArray($mine);
        $this->assertSame('driver_assigned', $mine['tracking']['stage']);
        $this->assertSame('01055551212', $mine['tracking']['driver']['phone']);

        Sanctum::actingAs($driver);
        $this->postJson('/api/trips/'.$tripId.'/start', [
            'start_lat' => 30.1,
            'start_lng' => 31.2,
        ])->assertOk();

        Sanctum::actingAs($employee);
        $this->getJson('/api/trip-requests/'.$requestId)
            ->assertOk()
            ->assertJsonPath('tracking.stage', 'in_progress');

        Sanctum::actingAs($driver);
        $this->postJson('/api/trips/'.$tripId.'/arrive', [
            'going_distance_m' => 100,
            'going_route' => self::POLYLINE,
        ])->assertOk();

        Sanctum::actingAs($employee);
        $this->getJson('/api/my-trips')
            ->assertOk()
            ->assertJsonPath('data.0.tracking.stage', 'in_progress');

        Sanctum::actingAs($driver);
        $this->postJson('/api/trips/'.$tripId.'/start-return')->assertOk();
        $this->postJson('/api/trips/'.$tripId.'/end', [
            'return_distance_m' => 40,
            'return_route' => self::POLYLINE,
        ])->assertOk();

        Sanctum::actingAs($employee);
        $finished = $this->getJson('/api/trip-requests/'.$requestId)
            ->assertOk()
            ->assertJsonPath('tracking.stage', 'awaiting_confirmation');
        $this->assertNotNull($this->timeline($finished->json('tracking'), 'finished')['reached_at']);

        $this->postJson('/api/trip-requests/'.$requestId.'/confirm-trip', [
            'driver_showed_up' => true,
        ])->assertOk()
            ->assertJsonPath('tracking.stage', 'confirmed');

        $confirmed = $this->getJson('/api/my-trips')->assertOk()->json('data.0.tracking');
        $this->assertSame('confirmed', $confirmed['stage']);
        $this->assertSame('employee', $this->timeline($confirmed, 'confirmed')['actor_role']);
    }

    public function test_rejection_includes_the_reason(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $request = $this->createPendingRequest($employee);

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests/'.$request->id.'/reject', [
                'rejection_reason' => 'No cars today',
            ])
            ->assertOk()
            ->assertJsonPath('tracking.stage', 'rejected')
            ->assertJsonPath('tracking.rejection_reason', 'No cars today')
            ->assertJsonPath('tracking.driver', null);

        Sanctum::actingAs($employee);
        $body = $this->getJson('/api/trip-requests/'.$request->id)->assertOk()->json('tracking');
        $this->assertSame('rejected', $body['stage']);
        $this->assertSame('company_admin', $this->timeline($body, 'rejected')['actor_role']);
        $this->assertArrayNotHasKey('driver_assigned', array_column($body['timeline'], 'stage', 'stage'));
    }

    public function test_auto_accepted_admin_requests_are_approved_by_their_own_role(): void
    {
        $company = $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated()
            ->assertJsonPath('tracking.stage', 'approved')
            ->json('tracking');
        $this->assertSame('company_admin', $this->timeline($company, 'approved')['actor_role']);
        $this->assertSame('company_admin', $this->timeline($company, 'submitted')['actor_role']);

        $drivers = $this->actingAsRole(UserRole::DriversAdmin)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated()
            ->assertJsonPath('tracking.stage', 'approved')
            ->json('tracking');
        $this->assertSame('drivers_admin', $this->timeline($drivers, 'approved')['actor_role']);
        $this->assertNull($drivers['driver']);
    }

    public function test_grouped_requesters_share_assignment_and_not_each_others_identity(): void
    {
        $first = $this->createUserWithRole(UserRole::Employee);
        $first->forceFill(['name_en' => 'Secret Ada', 'phone' => '01011110001'])->save();
        $second = $this->createUserWithRole(UserRole::Employee);
        $second->forceFill(['name_en' => 'Secret Bea', 'phone' => '01022220002'])->save();
        $requestA = $this->createPendingRequest($first);
        $requestA->notes = 'Ada private note';
        $requestA->save();
        $requestB = $this->createPendingRequest($second);
        $requestB->notes = 'Bea private note';
        $requestB->save();

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests/'.$requestA->id.'/approve')->assertOk();
        $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests/'.$requestB->id.'/approve')->assertOk();

        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $driver->forceFill(['name_en' => 'Shared Driver', 'phone' => '01099990000'])->save();

        Sanctum::actingAs($driversAdmin);
        $tripId = (string) $this->postJson('/api/trips/from-requests', [
            'mode' => 'grouped',
            'request_ids' => [$requestA->id, $requestB->id],
            'scheduled_at' => now()->addDays(3)->toISOString(),
        ])->assertCreated()->json('data.0.id');
        $this->postJson('/api/trips/'.$tripId.'/assign', ['driver_id' => $driver->id])->assertOk();

        Sanctum::actingAs($first);
        $ada = $this->getJson('/api/trip-requests/'.$requestA->id)->assertOk();
        $adaMine = $this->getJson('/api/my-trips')->assertOk();
        Sanctum::actingAs($second);
        $bea = $this->getJson('/api/trip-requests/'.$requestB->id)->assertOk();
        $beaMine = $this->getJson('/api/my-trips')->assertOk();

        $this->assertSame('driver_assigned', $ada->json('tracking.stage'));
        $this->assertSame('driver_assigned', $bea->json('tracking.stage'));
        $this->assertSame('01099990000', $ada->json('tracking.driver.phone'));
        $this->assertSame('01099990000', $bea->json('tracking.driver.phone'));
        $this->assertSame('driver_assigned', $adaMine->json('data.0.tracking.stage'));
        $this->assertSame('driver_assigned', $beaMine->json('data.0.tracking.stage'));

        $this->assertStringNotContainsString('Secret Bea', $ada->getContent());
        $this->assertStringNotContainsString('01022220002', $ada->getContent());
        $this->assertStringNotContainsString('Bea private note', $ada->getContent());
        $this->assertStringNotContainsString('Secret Ada', $bea->getContent());
        $this->assertStringNotContainsString('Ada private note', $bea->getContent());
        $this->assertStringNotContainsString('Secret Bea', $adaMine->getContent());
        $this->assertStringNotContainsString('Bea private note', $adaMine->getContent());
        $this->assertStringNotContainsString('Secret Ada', $beaMine->getContent());
        $this->assertStringNotContainsString('Ada private note', $beaMine->getContent());
        $this->assertArrayNotHasKey('notes', $ada->json('tracking'));
    }

    public function test_another_person_cannot_open_the_request_and_does_not_see_the_trip(): void
    {
        $owner = $this->createUserWithRole(UserRole::Employee);
        $other = $this->createUserWithRole(UserRole::Employee);
        $request = $this->createPendingRequest($owner);

        Sanctum::actingAs($other);
        $this->getJson('/api/trip-requests/'.$request->id)->assertForbidden();
        $this->getJson('/api/trip-requests/00000000-0000-4000-8000-000000000000')->assertNotFound();
        $ids = collect($this->getJson('/api/my-trips')->assertOk()->json('data'))->pluck('id');
        $this->assertFalse($ids->contains($request->id));

        Sanctum::actingAs($owner);
        $this->getJson('/api/trip-requests/'.$request->id)->assertOk()
            ->assertJsonPath('tracking.stage', 'submitted');
    }

    public function test_cancelled_request_and_cancelled_trip(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $pending = $this->createPendingRequest($employee);

        Sanctum::actingAs($employee);
        $this->postJson('/api/trip-requests/'.$pending->id.'/cancel')
            ->assertOk()
            ->assertJsonPath('tracking.stage', 'cancelled')
            ->assertJsonPath('tracking.timeline.1.actor_role', 'employee');

        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $approved = $this->createPendingRequest($employee);
        $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests/'.$approved->id.'/approve')->assertOk();
        Sanctum::actingAs($driversAdmin);
        $tripId = (string) $this->postJson('/api/trips/from-requests', [
            'mode' => 'one_per_request',
            'request_ids' => [$approved->id],
        ])->assertCreated()->json('data.0.id');
        $this->postJson('/api/trips/'.$tripId.'/assign', ['driver_id' => $driver->id])->assertOk();
        $this->postJson('/api/trips/'.$tripId.'/cancel')->assertOk();

        Sanctum::actingAs($employee);
        $cancelled = $this->getJson('/api/trip-requests/'.$approved->id)
            ->assertOk()
            ->assertJsonPath('tracking.stage', 'cancelled')
            ->json('tracking');
        $this->assertSame('drivers_admin', $this->timeline($cancelled, 'cancelled')['actor_role']);
        $this->assertNotNull($this->timeline($cancelled, 'driver_assigned')['reached_at']);
    }

    public function test_auto_unconfirmed_trip_has_no_actor(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);

        try {
            Carbon::setTestNow(Carbon::parse('2026-11-05 12:00:00', 'UTC'));
            $request = $this->createPendingRequest($employee);
            $this->actingAsRole(UserRole::CompanyAdmin)
                ->postJson('/api/trip-requests/'.$request->id.'/approve')->assertOk();
            Sanctum::actingAs($driversAdmin);
            $tripId = (string) $this->postJson('/api/trips/from-requests', [
                'mode' => 'one_per_request',
                'request_ids' => [$request->id],
            ])->assertCreated()->json('data.0.id');
            $this->postJson('/api/trips/'.$tripId.'/assign', ['driver_id' => $driver->id])->assertOk();
            Sanctum::actingAs($driver);
            $this->postJson('/api/trips/'.$tripId.'/start', ['start_lat' => 1, 'start_lng' => 1])->assertOk();
            $this->postJson('/api/trips/'.$tripId.'/arrive', [
                'going_distance_m' => 1,
                'going_route' => self::POLYLINE,
            ])->assertOk();
            $this->postJson('/api/trips/'.$tripId.'/start-return')->assertOk();
            $this->postJson('/api/trips/'.$tripId.'/end', [
                'return_distance_m' => 1,
                'return_route' => self::POLYLINE,
            ])->assertOk();

            Trip::query()->whereKey($tripId)->update([
                'confirmation_requested_at' => '2026-11-04 11:00:00',
            ]);

            $this->artisan('trips:auto-confirm')
                ->expectsOutput('Marked 1 trip(s) as unconfirmed.')
                ->assertSuccessful();

            Sanctum::actingAs($employee);
            $tracking = $this->getJson('/api/trip-requests/'.$request->id)
                ->assertOk()
                ->assertJsonPath('tracking.stage', 'unconfirmed')
                ->json('tracking');
            $this->assertNull($this->timeline($tracking, 'unconfirmed')['actor_role']);
            $this->assertSame(TripConfirmationStatus::Unconfirmed, Trip::query()->findOrFail($tripId)->confirmation_status);
        } finally {
            Carbon::setTestNow();
        }
    }

    public function test_backfill_copies_existing_approval_and_assignment_times(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $handledAt = Carbon::parse('2026-11-01 08:30:00', 'UTC');
        $request = $this->createPendingRequest($employee);
        $request->forceFill([
            'status' => 'approved',
            'handled_at' => $handledAt,
            'approved_at' => null,
        ])->save();

        $admin = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $updatedAt = Carbon::parse('2026-11-02 09:15:00', 'UTC');
        $trip = Trip::factory()->create([
            'created_by' => $admin->id,
            'driver_id' => $driver->id,
            'status' => TripStatus::Assigned,
            'assigned_at' => null,
        ]);
        DB::table('trips')->where('id', $trip->id)->update([
            'assigned_at' => null,
            'updated_at' => $updatedAt,
        ]);

        BackfillRequestTrackingTimestamps::run();

        $this->assertTrue($handledAt->equalTo($request->fresh()->approved_at));
        $this->assertTrue($updatedAt->equalTo($trip->fresh()->assigned_at));
    }

    /**
     * @param  array<string, mixed>  $tracking
     * @return array<string, mixed>
     */
    private function timeline(array $tracking, string $stage): array
    {
        foreach ($tracking['timeline'] as $event) {
            if ($event['stage'] === $stage) {
                return $event;
            }
        }

        $this->fail('Missing timeline stage '.$stage);
    }
}
