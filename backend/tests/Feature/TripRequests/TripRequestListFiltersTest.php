<?php

declare(strict_types=1);

namespace Tests\Feature\TripRequests;

use App\Domain\Enums\Branch;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripRequestListFiltersTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_branch_filter_uses_the_requesting_employee_and_omitted_returns_all(): void
    {
        $hq = $this->createUserWithRole(UserRole::Employee);
        $hq->branch = Branch::CompanyHeadquarters;
        $hq->save();
        $newHq = $this->createUserWithRole(UserRole::Employee);
        $newHq->branch = Branch::NewHeadquarters;
        $newHq->save();

        $hqRequest = $this->createPendingRequest($hq);
        $newRequest = $this->createPendingRequest($newHq);

        $this->actingAsRole(UserRole::CompanyAdmin);

        $all = collect($this->getJson('/api/trip-requests')->assertOk()->json('data'))->pluck('id');
        $this->assertTrue($all->contains($hqRequest->id));
        $this->assertTrue($all->contains($newRequest->id));

        $filtered = collect($this->getJson('/api/trip-requests?branch=new_headquarters')
            ->assertOk()
            ->json('data'))->pluck('id')->all();
        $this->assertSame([$newRequest->id], $filtered);

        $this->getJson('/api/trip-requests?branch=villa')->assertJsonValidationErrors(['branch']);
    }

    public function test_drivers_admin_list_is_always_approved_and_stage_splits_driver_assignment(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $pending = $this->createPendingRequest($employee);
        $needsDriver = $this->createApprovedUnlinkedRequest($employee);
        $assignedRequest = $this->createApprovedUnlinkedRequest($employee);
        $trip = $this->createUnassignedTrip($creator);
        $assignedRequest->trip_id = $trip->id;
        $assignedRequest->save();

        Sanctum::actingAs($creator);

        $ids = collect($this->getJson('/api/trip-requests')->assertOk()->json('data'))->pluck('id');
        $this->assertFalse($ids->contains($pending->id));
        $this->assertTrue($ids->contains($needsDriver->id));
        $this->assertTrue($ids->contains($assignedRequest->id));

        $forced = collect($this->getJson('/api/trip-requests?status=pending')->assertOk()->json('data'))
            ->pluck('id');
        $this->assertFalse($forced->contains($pending->id));
        $this->assertTrue($forced->contains($needsDriver->id));

        $needs = collect($this->getJson('/api/trip-requests?stage=needs_driver')->assertOk()->json('data'))
            ->pluck('id')->all();
        $this->assertSame([$needsDriver->id], $needs);
        $this->assertNull(collect($this->getJson('/api/trip-requests?stage=needs_driver')->json('data'))
            ->firstWhere('id', $needsDriver->id)['trip_status']);

        $assigned = $this->getJson('/api/trip-requests?stage=assigned')->assertOk()->json('data');
        $this->assertSame([$assignedRequest->id], collect($assigned)->pluck('id')->all());
        $this->assertSame('unassigned', collect($assigned)->firstWhere('id', $assignedRequest->id)['trip_status']);

        $this->getJson('/api/trip-requests?stage=in_progress')->assertJsonValidationErrors(['stage']);
    }

    public function test_company_admin_list_still_returns_other_statuses(): void
    {
        $employee = $this->createUserWithRole(UserRole::Employee);
        $pending = $this->createPendingRequest($employee);
        $approved = $this->createApprovedUnlinkedRequest($employee);

        $this->actingAsRole(UserRole::CompanyAdmin);
        $ids = collect($this->getJson('/api/trip-requests')->assertOk()->json('data'))->pluck('id');
        $this->assertTrue($ids->contains($pending->id));
        $this->assertTrue($ids->contains($approved->id));

        $onlyPending = collect($this->getJson('/api/trip-requests?status=pending')->assertOk()->json('data'))
            ->pluck('id')->all();
        $this->assertSame([$pending->id], $onlyPending);
    }

    public function test_mine_buckets_include_the_linked_trip_status(): void
    {
        $admin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $other = $this->createUserWithRole(UserRole::Employee);

        $pending = $this->createPendingRequest($admin);
        $approvedOpen = $this->createApprovedUnlinkedRequest($admin);
        $going = $this->linked($admin, $creator, TripStatus::Going);
        $completed = $this->linked($admin, $creator, TripStatus::Completed);
        $cancelledTrip = $this->linked($admin, $creator, TripStatus::Cancelled);
        $rejected = $this->createPendingRequest($admin);
        $rejected->status = TripRequestStatus::Rejected;
        $rejected->save();
        $cancelledRequest = $this->createPendingRequest($admin);
        $cancelledRequest->status = TripRequestStatus::Cancelled;
        $cancelledRequest->save();
        $someoneElse = $this->createPendingRequest($other);

        Sanctum::actingAs($admin);

        $active = $this->idsAndStatuses('/api/trip-requests/mine?bucket=active');
        $this->assertEqualsCanonicalizing(
            [$pending->id, $approvedOpen->id, $going['id']],
            array_keys($active),
        );
        $this->assertNull($active[$pending->id]);
        $this->assertNull($active[$approvedOpen->id]);
        $this->assertSame('going', $active[$going['id']]);
        $this->assertArrayNotHasKey($someoneElse->id, $active);

        $done = $this->idsAndStatuses('/api/trip-requests/mine?bucket=completed');
        $this->assertSame([$completed['id'] => 'completed'], $done);

        $cancelled = $this->idsAndStatuses('/api/trip-requests/mine?bucket=cancelled');
        $this->assertEqualsCanonicalizing(
            [$cancelledTrip['id'], $rejected->id, $cancelledRequest->id],
            array_keys($cancelled),
        );
        $this->assertSame('cancelled', $cancelled[$cancelledTrip['id']]);
        $this->assertNull($cancelled[$rejected->id]);
        $this->assertNull($cancelled[$cancelledRequest->id]);

        $everything = $this->idsAndStatuses('/api/trip-requests/mine');
        $this->assertCount(7, $everything);

        $this->getJson('/api/trip-requests/mine?bucket=archived')->assertJsonValidationErrors(['bucket']);
    }

    /**
     * @return array{id: string}
     */
    private function linked(User $employee, User $creator, TripStatus $status): array
    {
        $trip = Trip::factory()->create([
            'created_by' => $creator->id,
            'status' => $status,
            'driver_id' => null,
        ]);
        $request = $this->createApprovedUnlinkedRequest($employee);
        $request->trip_id = $trip->id;
        $request->save();

        return ['id' => $request->id];
    }

    /**
     * @return array<string, ?string>
     */
    private function idsAndStatuses(string $url): array
    {
        $rows = $this->getJson($url)->assertOk()->json('data');
        $mapped = [];
        foreach ($rows as $row) {
            $mapped[$row['id']] = $row['trip_status'];
        }

        return $mapped;
    }
}
