<?php

declare(strict_types=1);

namespace Tests\Feature\TripRequests;

use App\Domain\Enums\Branch;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;
use App\Models\Place;
use App\Models\TripRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class GroupingSuggestionMembersTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_suggestions_keep_request_ids_and_add_member_summaries(): void
    {
        $place = Place::factory()->create([
            'name_en' => 'Plant',
            'is_active' => true,
        ]);
        $earlier = $this->requester('Sara Nabil', 'سارة نبيل', Branch::CompanyHeadquarters);
        $later = $this->requester('Omar Fathy', null, Branch::NewHeadquarters);
        $first = $this->request($earlier, $place, TripRequestStatus::Pending, '2026-11-10 08:00:00', 'HQ gate');
        $second = $this->request($later, $place, TripRequestStatus::Pending, '2026-11-10 11:00:00', 'Villa');

        $this->actingAsRole(UserRole::CompanyAdmin);
        $suggestion = $this->getJson('/api/trip-requests/grouping-suggestions')
            ->assertOk()
            ->json('data.0');

        $expectedIds = [$first->id, $second->id];
        sort($expectedIds);
        $this->assertSame($expectedIds, $suggestion['request_ids']);
        $this->assertSame($first->id, $suggestion['members'][0]['request_id']);
        $this->assertSame('Sara Nabil', $suggestion['members'][0]['requester_name_en']);
        $this->assertSame('سارة نبيل', $suggestion['members'][0]['requester_name_ar']);
        $this->assertSame(Branch::CompanyHeadquarters->value, $suggestion['members'][0]['branch']);
        $this->assertSame('HQ gate', $suggestion['members'][0]['from_place']);
        $this->assertSame('Plant', $suggestion['members'][0]['to_place']);
        $this->assertSame($first->fresh()->requested_at->format(DATE_ATOM), $suggestion['members'][0]['requested_at']);
        $this->assertSame($second->id, $suggestion['members'][1]['request_id']);
        $this->assertNull($suggestion['members'][1]['requester_name_ar']);
        $this->assertSame(Branch::NewHeadquarters->value, $suggestion['members'][1]['branch']);
        $this->assertSame('Villa', $suggestion['members'][1]['from_place']);
        $this->assertArrayNotHasKey('meta', $this->getJson('/api/trip-requests/grouping-suggestions')->json());

        $approvedFirst = $this->request($earlier, $place, TripRequestStatus::Approved, '2026-11-11 08:00:00', 'HQ gate');
        $approvedSecond = $this->request($later, $place, TripRequestStatus::Approved, '2026-11-11 09:00:00', 'Villa');

        $this->actingAsRole(UserRole::DriversAdmin);
        $approved = $this->getJson('/api/trip-requests/grouping-suggestions')->assertOk()->json('data.0');
        $this->assertEqualsCanonicalizing(
            [$approvedFirst->id, $approvedSecond->id],
            $approved['request_ids'],
        );
        $this->assertCount(2, $approved['members']);
        $this->assertSame($approvedFirst->id, $approved['members'][0]['request_id']);

        $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/trip-requests/grouping-suggestions')
            ->assertForbidden();
        $this->actingAsRole(UserRole::Employee)
            ->getJson('/api/trip-requests/grouping-suggestions')
            ->assertForbidden();
        $this->actingAsRole(UserRole::Driver)
            ->getJson('/api/trip-requests/grouping-suggestions')
            ->assertForbidden();
    }

    private function requester(string $nameEn, ?string $nameAr, Branch $branch): User
    {
        $user = $this->createUserWithRole(UserRole::Employee);
        $user->name_en = $nameEn;
        $user->name_ar = $nameAr;
        $user->branch = $branch;
        $user->save();

        return $user;
    }

    private function request(
        User $employee,
        Place $place,
        TripRequestStatus $status,
        string $requestedAt,
        string $from,
    ): TripRequest {
        return TripRequest::factory()->create([
            'employee_id' => $employee->id,
            'requester_role' => UserRole::Employee,
            'status' => $status,
            'pickup_name' => $from,
            'destination_place_id' => $place->id,
            'destination_name' => $place->name_en,
            'requested_at' => $requestedAt,
            'trip_id' => null,
        ]);
    }
}
