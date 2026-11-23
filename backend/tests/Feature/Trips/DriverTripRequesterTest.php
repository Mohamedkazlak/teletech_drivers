<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\Branch;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\DriverProfile;
use App\Models\Trip;
use App\Models\TripRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class DriverTripRequesterTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    /**
     * @return array<string, array{0: UserRole}>
     */
    public static function requesterRoles(): array
    {
        return [
            'employee' => [UserRole::Employee],
            'company_admin' => [UserRole::CompanyAdmin],
            'drivers_admin' => [UserRole::DriversAdmin],
        ];
    }

    #[DataProvider('requesterRoles')]
    public function test_assigned_driver_sees_requester_and_count_on_list_and_detail(UserRole $role): void
    {
        $requester = $this->requester($role, '01012345678', 'Sara Nabil', 'سارة نبيل');
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->assignedTrip($creator, $driver, TripStatus::Assigned);
        $this->linkRequest($requester, $trip, "Fellow Omar\nFELLOW-PHONE-DO-NOT-SHARE");

        Sanctum::actingAs($driver);

        $list = $this->getJson('/api/trips/mine?status=assigned')->assertOk();
        $this->assertRequesterPayload($list, 'data.0', $requester, 1);
        $this->assertNoContactLeak($list);

        $detail = $this->getJson('/api/trips/'.$trip->id)->assertOk();
        $this->assertRequesterPayload($detail, '', $requester, 1);
        $this->assertSame($creator->id, $detail->json('created_by'));
        $this->assertNotSame($creator->id, $detail->json('requester.id'));
        $this->assertNoContactLeak($detail);
    }

    public function test_completed_trip_list_includes_the_requester(): void
    {
        $requester = $this->requester(UserRole::Employee, '01012345678', 'Sara Nabil', 'سارة نبيل');
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->assignedTrip($creator, $driver, TripStatus::Completed);
        $this->linkRequest($requester, $trip, null);

        Sanctum::actingAs($driver);

        $list = $this->getJson('/api/trips/mine?status=completed')->assertOk();
        $this->assertRequesterPayload($list, 'data.0', $requester, 1);
        $this->assertSame($trip->id, $list->json('data.0.id'));
    }

    public function test_another_driver_cannot_read_the_requester(): void
    {
        $requester = $this->requester(UserRole::Employee, '01012345678', 'Sara Nabil', 'سارة نبيل');
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $other = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->assignedTrip($creator, $driver, TripStatus::Assigned);
        $this->linkRequest($requester, $trip, null);

        Sanctum::actingAs($other);

        $this->getJson('/api/trips/'.$trip->id)->assertForbidden();
        $this->getJson('/api/trips/mine')
            ->assertOk()
            ->assertJsonCount(0, 'data')
            ->assertJsonMissing(['phone' => '01012345678']);
    }

    public function test_grouped_trip_returns_every_requester_and_the_summed_count(): void
    {
        $first = $this->requester(UserRole::Employee, '01011110001', 'Sara Nabil', 'سارة نبيل');
        $second = $this->requester(UserRole::CompanyAdmin, '01011110002', 'Omar Fathy', 'عمر فتحي');
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $trip = $this->assignedTrip($creator, $driver, TripStatus::Assigned);
        $this->linkRequest($first, $trip, "Fellow\nFELLOW-PHONE-DO-NOT-SHARE");
        $this->linkRequest($second, $trip, null);

        Sanctum::actingAs($driver);

        $detail = $this->getJson('/api/trips/'.$trip->id)->assertOk();
        $detail->assertJsonPath('passenger_count', 2);
        $detail->assertJsonCount(2, 'requesters');

        $ids = collect($detail->json('requesters'))->pluck('id')->all();
        $phones = collect($detail->json('requesters'))->pluck('phone')->all();
        $this->assertEqualsCanonicalizing([$first->id, $second->id], $ids);
        $this->assertEqualsCanonicalizing(['01011110001', '01011110002'], $phones);
        $this->assertNotContains($creator->id, $ids);
        $this->assertNoContactLeak($detail);

        foreach ($detail->json('requesters') as $entry) {
            $this->assertSame(
                ['id', 'name_en', 'name_ar', 'phone', 'branch'],
                array_keys($entry),
            );
        }
    }

    private function requester(UserRole $role, string $phone, string $nameEn, string $nameAr): User
    {
        $user = $this->createUserWithRole($role);
        $user->forceFill([
            'name_en' => $nameEn,
            'name_ar' => $nameAr,
            'phone' => $phone,
            'email' => 'secret-'.$role->value.'-'.$user->id.'@example.com',
            'branch' => Branch::CompanyHeadquarters,
        ])->save();

        DriverProfile::query()->updateOrCreate(
            ['user_id' => $user->id],
            [
                'national_id' => 'SECRET-NID-'.$user->id,
                'car_license' => 'SECRET-CAR',
                'personal_license' => 'SECRET-LICENSE',
            ],
        );

        return $user->fresh();
    }

    private function assignedTrip(User $creator, User $driver, TripStatus $status): Trip
    {
        return Trip::factory()->create([
            'created_by' => $creator->id,
            'driver_id' => $driver->id,
            'status' => $status,
            'finished_at' => $status === TripStatus::Completed ? now() : null,
        ]);
    }

    private function linkRequest(User $requester, Trip $trip, ?string $notes): TripRequest
    {
        return TripRequest::factory()->approved()->create([
            'employee_id' => $requester->id,
            'requester_role' => $requester->role,
            'trip_id' => $trip->id,
            'notes' => $notes ?? '',
            'handled_by' => $requester->id,
        ]);
    }

    private function assertRequesterPayload(
        TestResponse $response,
        string $prefix,
        User $requester,
        int $count,
    ): void {
        $path = $prefix === '' ? '' : $prefix.'.';
        $response
            ->assertJsonPath($path.'requester.id', $requester->id)
            ->assertJsonPath($path.'requester.name_en', $requester->name_en)
            ->assertJsonPath($path.'requester.name_ar', $requester->name_ar)
            ->assertJsonPath($path.'requester.phone', $requester->phone)
            ->assertJsonPath($path.'requester.branch', Branch::CompanyHeadquarters->value)
            ->assertJsonPath($path.'passenger_count', $count)
            ->assertJsonPath($path.'requesters.0.id', $requester->id)
            ->assertJsonPath($path.'requesters.0.phone', $requester->phone);

        $requesterPayload = $response->json($path.'requester');
        $this->assertSame(
            ['id', 'name_en', 'name_ar', 'phone', 'branch'],
            array_keys($requesterPayload),
        );
    }

    private function assertNoContactLeak(TestResponse $response): void
    {
        $encoded = json_encode($response->json(), JSON_THROW_ON_ERROR);

        $this->assertStringNotContainsString('secret-', $encoded);
        $this->assertStringNotContainsString('SECRET-NID-', $encoded);
        $this->assertStringNotContainsString('SECRET-CAR', $encoded);
        $this->assertStringNotContainsString('SECRET-LICENSE', $encoded);
        $this->assertStringNotContainsString('FELLOW-PHONE-DO-NOT-SHARE', $encoded);
        $this->assertStringNotContainsString('national_id', $encoded);

        foreach ($this->passengerRows($response) as $passenger) {
            $this->assertArrayNotHasKey('email', $passenger);
            $this->assertArrayNotHasKey('national_id', $passenger);
        }
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function passengerRows(TestResponse $response): array
    {
        $payload = $response->json();
        $rows = $payload['passengers'] ?? $payload['data'][0]['passengers'] ?? [];

        return is_array($rows) ? $rows : [];
    }
}
