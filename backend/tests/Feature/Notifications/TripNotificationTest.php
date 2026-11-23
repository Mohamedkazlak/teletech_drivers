<?php

declare(strict_types=1);

namespace Tests\Feature\Notifications;

use App\Domain\Enums\NotificationType;
use App\Domain\Enums\UserRole;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripNotificationTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    private const POLYLINE = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

    public function test_employee_request_notifies_every_active_company_admin_except_the_actor(): void
    {
        $firstAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $secondAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $inactive = $this->createUserWithRole(UserRole::CompanyAdmin);
        $inactive->forceFill(['is_active' => false])->save();
        $driversAdmin = $this->createUserWithRole(UserRole::DriversAdmin);
        $employee = $this->createUserWithRole(UserRole::Employee);
        $employee->forceFill(['name_en' => 'Sara Adel', 'name_ar' => 'سارة عادل'])->save();

        Sanctum::actingAs($employee);
        $created = $this->postJson('/api/trip-requests', $this->tripRequestPayload())->assertCreated();

        $this->assertSame(1, $this->countType($firstAdmin, NotificationType::RequestSubmitted));
        $this->assertSame(1, $this->countType($secondAdmin, NotificationType::RequestSubmitted));
        $this->assertSame(0, $this->countType($inactive, NotificationType::RequestSubmitted));
        $this->assertSame(0, Notification::query()->where('user_id', $employee->id)->count());
        $this->assertSame(0, Notification::query()->where('user_id', $driversAdmin->id)->count());

        Sanctum::actingAs($firstAdmin);
        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonPath('data.0.type', NotificationType::RequestSubmitted->value)
            ->assertJsonPath('data.0.title_key', 'notifications.request_submitted.title')
            ->assertJsonPath('data.0.trip_request_id', $created->json('id'))
            ->assertJsonPath('data.0.trip_id', null)
            ->assertJsonPath('data.0.title', 'New trip request')
            ->assertJsonPath('data.0.body', 'Sara Adel requested a trip from Pickup to Destination.')
            ->assertJsonPath('data.0.read_at', null);

        $this->withHeader('Accept-Language', 'ar')
            ->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonPath('data.0.title', 'طلب رحلة جديد')
            ->assertJsonPath('data.0.body', 'طلب سارة عادل رحلة من Pickup إلى Destination.');
    }

    public function test_company_admin_approval_notifies_drivers_admins_and_not_the_actor(): void
    {
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $firstFleet = $this->createUserWithRole(UserRole::DriversAdmin);
        $secondFleet = $this->createUserWithRole(UserRole::DriversAdmin);
        $employee = $this->createUserWithRole(UserRole::Employee);
        $request = $this->createPendingRequest($employee);

        Sanctum::actingAs($companyAdmin);
        $this->postJson('/api/trip-requests/'.$request->id.'/approve')->assertOk();

        $this->assertSame(1, $this->countType($firstFleet, NotificationType::TripReadyToAssign));
        $this->assertSame(1, $this->countType($secondFleet, NotificationType::TripReadyToAssign));
        $this->assertSame(0, Notification::query()->where('user_id', $companyAdmin->id)->count());
        $this->assertSame(0, Notification::query()->where('user_id', $employee->id)->count());
        $this->assertSame($request->id, Notification::query()->where('user_id', $firstFleet->id)->value('trip_request_id'));
    }

    public function test_group_approval_notifies_drivers_admins_once_per_request(): void
    {
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $fleet = $this->createUserWithRole(UserRole::DriversAdmin);
        $employee = $this->createUserWithRole(UserRole::Employee);
        $first = $this->createPendingRequest($employee);
        $second = $this->createPendingRequest($employee);

        Sanctum::actingAs($companyAdmin);
        $this->postJson('/api/trip-requests/approve-group', [
            'request_ids' => [$first->id, $second->id],
        ])->assertOk();

        $this->assertSame(2, $this->countType($fleet, NotificationType::TripReadyToAssign));
        $this->assertSame(0, Notification::query()->where('user_id', $companyAdmin->id)->count());
    }

    public function test_company_admin_own_request_notifies_drivers_admins_only(): void
    {
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $otherCompanyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $fleet = $this->createUserWithRole(UserRole::DriversAdmin);

        Sanctum::actingAs($companyAdmin);
        $created = $this->postJson('/api/trip-requests', $this->tripRequestPayload())->assertCreated();

        $this->assertSame(1, $this->countType($fleet, NotificationType::TripReadyToAssign));
        $this->assertSame(0, $this->countType($fleet, NotificationType::RequestSubmitted));
        $this->assertSame(0, Notification::query()->where('user_id', $companyAdmin->id)->count());
        $this->assertSame(0, Notification::query()->where('user_id', $otherCompanyAdmin->id)->count());
        $this->assertSame($created->json('id'), Notification::query()->where('user_id', $fleet->id)->value('trip_request_id'));
    }

    public function test_admin_own_request_does_not_notify(): void
    {
        $this->createUserWithRole(UserRole::DriversAdmin);
        $this->createUserWithRole(UserRole::CompanyAdmin);

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated();

        $this->assertDatabaseCount('notifications', 0);
    }

    public function test_drivers_admin_own_request_skips_ready_to_assign_and_notifies_on_driver_pick(): void
    {
        $owner = $this->createUserWithRole(UserRole::DriversAdmin);
        $otherFleet = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $driver->forceFill(['name_en' => 'Omar Nabil', 'name_ar' => 'عمر نبيل'])->save();

        Sanctum::actingAs($owner);
        $created = $this->postJson('/api/trip-requests', $this->tripRequestPayload())->assertCreated();
        $tripId = (string) $created->json('trip_id');

        $this->assertDatabaseCount('notifications', 0);

        $this->postJson('/api/trips/'.$tripId.'/assign', ['driver_id' => $driver->id])->assertOk();

        $this->assertSame(0, $this->countType($owner, NotificationType::TripReadyToAssign));
        $this->assertSame(0, $this->countType($owner, NotificationType::TripAssigned));
        $this->assertSame(1, $this->countType($owner, NotificationType::OwnTripAssigned));
        $this->assertSame(0, Notification::query()->where('user_id', $otherFleet->id)->count());
        $this->assertSame(1, $this->countType($driver, NotificationType::TripAssigned));
        $this->assertSame(0, $this->countType($driver, NotificationType::OwnTripAssigned));

        Sanctum::actingAs($owner);
        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonPath('data.0.type', NotificationType::OwnTripAssigned->value)
            ->assertJsonPath('data.0.body', 'Omar Nabil is assigned to your trip from Pickup to Destination.')
            ->assertJsonPath('data.0.trip_id', $tripId)
            ->assertJsonPath('data.0.trip_request_id', $created->json('id'));
    }

    public function test_assigning_an_employee_trip_notifies_requester_and_driver_not_the_actor(): void
    {
        [$fleet, $driver, $employee, $tripId] = $this->assignedEmployeeTrip();

        $this->assertSame(1, $this->countType($employee, NotificationType::TripAssigned));
        $this->assertSame(0, $this->countType($employee, NotificationType::OwnTripAssigned));
        $this->assertSame(1, $this->countType($driver, NotificationType::TripAssigned));
        $this->assertSame(0, Notification::query()->where('user_id', $fleet->id)->where('type', NotificationType::TripAssigned->value)->count());
        $this->assertSame(0, $this->countType($fleet, NotificationType::OwnTripAssigned));
        $this->assertNotNull($tripId);
    }

    public function test_reassign_notifies_the_new_driver_and_the_requester_again(): void
    {
        [$fleet, $firstDriver, $employee, $tripId] = $this->assignedEmployeeTrip();
        $secondDriver = $this->createUserWithRole(UserRole::Driver);

        Sanctum::actingAs($fleet);
        $this->postJson('/api/trips/'.$tripId.'/assign', ['driver_id' => $secondDriver->id])->assertOk();

        $this->assertSame(2, $this->countType($employee, NotificationType::TripAssigned));
        $this->assertSame(1, $this->countType($firstDriver, NotificationType::TripAssigned));
        $this->assertSame(1, $this->countType($secondDriver, NotificationType::TripAssigned));
        $this->assertSame(0, $this->countType($fleet, NotificationType::TripAssigned));
    }

    public function test_company_admin_own_trip_uses_own_trip_assigned(): void
    {
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $fleet = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);

        Sanctum::actingAs($companyAdmin);
        $created = $this->postJson('/api/trip-requests', $this->tripRequestPayload())->assertCreated();

        Sanctum::actingAs($fleet);
        $tripId = (string) $this->postJson('/api/trips/from-requests', [
            'mode' => 'one_per_request',
            'request_ids' => [$created->json('id')],
        ])->assertCreated()->json('data.0.id');

        $readyBeforeAssign = $this->countType($fleet, NotificationType::TripReadyToAssign);
        $this->postJson('/api/trips/'.$tripId.'/assign', ['driver_id' => $driver->id])->assertOk();

        $this->assertSame($readyBeforeAssign, $this->countType($fleet, NotificationType::TripReadyToAssign));
        $this->assertSame(0, $this->countType($fleet, NotificationType::TripAssigned));
        $this->assertSame(0, $this->countType($fleet, NotificationType::OwnTripAssigned));
        $this->assertSame(1, $this->countType($companyAdmin, NotificationType::OwnTripAssigned));
        $this->assertSame(0, $this->countType($companyAdmin, NotificationType::TripAssigned));
        $this->assertSame(1, $this->countType($driver, NotificationType::TripAssigned));
    }

    public function test_grouped_trip_notifies_every_requester_on_assign_and_end(): void
    {
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $fleet = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $employee = $this->createUserWithRole(UserRole::Employee);

        Sanctum::actingAs($employee);
        $employeeRequest = $this->postJson('/api/trip-requests', $this->tripRequestPayload())->assertCreated();

        Sanctum::actingAs($companyAdmin);
        $this->postJson('/api/trip-requests/'.$employeeRequest->json('id').'/approve')->assertOk();
        $ownRequest = $this->postJson('/api/trip-requests', $this->tripRequestPayload())->assertCreated();

        Sanctum::actingAs($fleet);
        $tripId = (string) $this->postJson('/api/trips/from-requests', [
            'mode' => 'grouped',
            'request_ids' => [$employeeRequest->json('id'), $ownRequest->json('id')],
            'scheduled_at' => now()->addDays(2)->toIso8601String(),
        ])->assertCreated()->json('data.0.id');

        $this->postJson('/api/trips/'.$tripId.'/assign', ['driver_id' => $driver->id])->assertOk();

        $this->assertSame(1, $this->countType($employee, NotificationType::TripAssigned));
        $this->assertSame(0, $this->countType($employee, NotificationType::OwnTripAssigned));
        $this->assertSame(1, $this->countType($companyAdmin, NotificationType::OwnTripAssigned));
        $this->assertSame(0, $this->countType($companyAdmin, NotificationType::TripAssigned));
        $this->assertSame(1, $this->countType($driver, NotificationType::TripAssigned));
        $this->assertNull(
            Notification::query()
                ->where('user_id', $driver->id)
                ->where('type', NotificationType::TripAssigned->value)
                ->value('trip_request_id'),
        );
        $this->assertSame(0, $this->countType($fleet, NotificationType::TripAssigned));
        $this->assertSame(0, $this->countType($fleet, NotificationType::OwnTripAssigned));

        $this->finish($driver, $tripId);

        $this->assertSame(1, $this->countType($employee, NotificationType::TripEndedReportNeeded));
        $this->assertSame(1, $this->countType($companyAdmin, NotificationType::TripEndedReportNeeded));
        $this->assertSame(0, $this->countType($driver, NotificationType::TripEndedReportNeeded));
        $this->assertSame(0, $this->countType($fleet, NotificationType::TripEndedReportNeeded));
    }

    public function test_ending_a_trip_notifies_the_requester_and_not_the_driver(): void
    {
        [$fleet, $driver, $employee, $tripId] = $this->assignedEmployeeTrip();

        $this->finish($driver, $tripId);

        $this->assertSame(1, $this->countType($employee, NotificationType::TripEndedReportNeeded));
        $this->assertSame(0, $this->countType($driver, NotificationType::TripEndedReportNeeded));
        $this->assertSame(0, $this->countType($fleet, NotificationType::TripEndedReportNeeded));

        Sanctum::actingAs($employee);
        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonFragment(['type' => NotificationType::TripEndedReportNeeded->value])
            ->assertJsonFragment(['title' => 'Trip ended']);
    }

    public function test_auto_confirm_does_not_create_notifications(): void
    {
        [, $driver, , $tripId] = $this->assignedEmployeeTrip();
        $this->finish($driver, $tripId);

        $before = Notification::query()->orderBy('id')->pluck('id')->all();

        $this->travelTo(now()->addHours(25));
        $this->artisan('trips:auto-confirm')->assertSuccessful();

        $this->assertSame($before, Notification::query()->orderBy('id')->pluck('id')->all());
    }

    public function test_notification_failure_rolls_back_the_request(): void
    {
        $this->createUserWithRole(UserRole::CompanyAdmin);
        $this->actingAsRole(UserRole::Employee);

        DB::listen(function ($query): void {
            $sql = strtolower($query->sql);
            if (str_contains($sql, 'insert') && str_contains($sql, 'notifications')) {
                throw new \RuntimeException('Simulated notification failure');
            }
        });

        try {
            $this->withoutExceptionHandling();
            $this->postJson('/api/trip-requests', $this->tripRequestPayload());
            $this->fail('Expected the notification insert to fail');
        } catch (\RuntimeException $e) {
            $this->assertSame('Simulated notification failure', $e->getMessage());
        }

        $this->assertDatabaseCount('trip_requests', 0);
        $this->assertDatabaseCount('notifications', 0);
    }

    /**
     * @return array{0: User, 1: User, 2: User, 3: string}
     */
    private function assignedEmployeeTrip(): array
    {
        $companyAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $fleet = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $employee = $this->createUserWithRole(UserRole::Employee);

        Sanctum::actingAs($employee);
        $created = $this->postJson('/api/trip-requests', $this->tripRequestPayload())->assertCreated();

        Sanctum::actingAs($companyAdmin);
        $this->postJson('/api/trip-requests/'.$created->json('id').'/approve')->assertOk();

        Sanctum::actingAs($fleet);
        $tripId = (string) $this->postJson('/api/trips/from-requests', [
            'mode' => 'one_per_request',
            'request_ids' => [$created->json('id')],
        ])->assertCreated()->json('data.0.id');

        $this->postJson('/api/trips/'.$tripId.'/assign', ['driver_id' => $driver->id])->assertOk();

        return [$fleet, $driver, $employee, $tripId];
    }

    private function finish(User $driver, string $tripId): void
    {
        Sanctum::actingAs($driver);
        $this->postJson('/api/trips/'.$tripId.'/start', [
            'start_lat' => 30.1,
            'start_lng' => 31.2,
        ])->assertOk();
        $this->postJson('/api/trips/'.$tripId.'/arrive', [
            'going_distance_m' => 100,
            'going_route' => self::POLYLINE,
        ])->assertOk();
        $this->postJson('/api/trips/'.$tripId.'/start-return')->assertOk();
        $this->postJson('/api/trips/'.$tripId.'/end', [
            'return_distance_m' => 40,
            'return_route' => self::POLYLINE,
        ])->assertOk();
    }

    private function countType(User $user, NotificationType $type): int
    {
        return Notification::query()
            ->where('user_id', $user->id)
            ->where('type', $type->value)
            ->count();
    }
}
