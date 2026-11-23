<?php

declare(strict_types=1);

namespace Tests\Feature\TripRequests;

use App\Domain\Enums\UserRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class PastScheduleValidationTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    /**
     * @return list<array{0: UserRole}>
     */
    public static function requestCreators(): array
    {
        return [
            [UserRole::Employee],
            [UserRole::CompanyAdmin],
            [UserRole::DriversAdmin],
        ];
    }

    #[DataProvider('requestCreators')]
    public function test_past_requested_at_is_rejected_for_every_creator(UserRole $role): void
    {
        $this->travelTo(Carbon::parse('2026-11-16 14:00:00', 'Africa/Cairo'));

        $this->actingAsRole($role)
            ->postJson('/api/trip-requests', $this->payloadAt('2026-11-16 13:59:00'))
            ->assertStatus(422)
            ->assertJsonPath('errors.scheduled_at.0', 'The scheduled time must be in the future.')
            ->assertJsonPath('errors.requested_at.0', 'The scheduled time must be in the future.');

        $this->assertDatabaseCount('trip_requests', 0);
        $this->assertDatabaseCount('trips', 0);
    }

    #[DataProvider('requestCreators')]
    public function test_future_requested_at_is_accepted_for_every_creator(UserRole $role): void
    {
        $this->travelTo(Carbon::parse('2026-11-16 14:00:00', 'Africa/Cairo'));

        $this->actingAsRole($role)
            ->postJson('/api/trip-requests', $this->payloadAt('2026-11-16 14:01:00'))
            ->assertCreated();
    }

    public function test_exactly_now_in_cairo_is_rejected(): void
    {
        $this->travelTo(Carbon::parse('2026-11-16 14:00:00', 'Africa/Cairo'));

        $this->actingAsRole(UserRole::Employee)
            ->postJson('/api/trip-requests', $this->payloadAt('2026-11-16 14:00:00'))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['scheduled_at', 'requested_at']);
    }

    public function test_utc_instant_is_compared_with_cairo_now(): void
    {
        $this->travelTo(Carbon::parse('2026-11-16 14:00:00', 'Africa/Cairo'));

        $this->actingAsRole(UserRole::Employee)
            ->postJson('/api/trip-requests', $this->payloadIso('2026-11-16T11:59:00+00:00'))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['scheduled_at']);

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->postJson('/api/trip-requests', $this->payloadIso('2026-11-16T12:01:00+00:00'))
            ->assertCreated();
    }

    public function test_past_schedule_message_is_arabic_when_requested(): void
    {
        $this->travelTo(Carbon::parse('2026-11-16 14:00:00', 'Africa/Cairo'));

        $this->actingAsRole(UserRole::Employee)
            ->withHeader('Accept-Language', 'ar')
            ->postJson('/api/trip-requests', $this->payloadAt('2026-11-16 13:59:00'))
            ->assertStatus(422)
            ->assertJsonPath('errors.scheduled_at.0', 'يجب أن يكون موعد الرحلة في المستقبل.')
            ->assertJsonPath('errors.requested_at.0', 'يجب أن يكون موعد الرحلة في المستقبل.');
    }

    public function test_grouped_trip_rejects_a_past_scheduled_at_and_writes_nothing(): void
    {
        $this->travelTo(Carbon::parse('2026-11-16 14:00:00', 'Africa/Cairo'));
        $employee = $this->createUserWithRole(UserRole::Employee);
        $first = $this->createApprovedUnlinkedRequest($employee);
        $second = $this->createApprovedUnlinkedRequest($employee);

        $this->actingAsRole(UserRole::DriversAdmin)
            ->postJson('/api/trips/from-requests', [
                'mode' => 'grouped',
                'request_ids' => [$first->id, $second->id],
                'scheduled_at' => Carbon::parse('2026-11-16 13:59:00', 'Africa/Cairo')->toAtomString(),
            ])
            ->assertStatus(422)
            ->assertJsonPath('errors.scheduled_at.0', 'The scheduled time must be in the future.');

        $this->assertNull($first->fresh()->trip_id);
        $this->assertNull($second->fresh()->trip_id);
        $this->assertDatabaseCount('trips', 0);
    }

    public function test_arabic_past_scheduled_at_on_grouped_trip(): void
    {
        $this->travelTo(Carbon::parse('2026-11-16 14:00:00', 'Africa/Cairo'));
        $employee = $this->createUserWithRole(UserRole::Employee);
        $first = $this->createApprovedUnlinkedRequest($employee);
        $second = $this->createApprovedUnlinkedRequest($employee);

        $this->actingAsRole(UserRole::DriversAdmin)
            ->withHeader('Accept-Language', 'ar-EG,ar;q=0.9')
            ->postJson('/api/trips/from-requests', [
                'mode' => 'grouped',
                'request_ids' => [$first->id, $second->id],
                'scheduled_at' => Carbon::parse('2026-11-16 13:59:00', 'Africa/Cairo')->toAtomString(),
            ])
            ->assertStatus(422)
            ->assertJsonPath('errors.scheduled_at.0', 'يجب أن يكون موعد الرحلة في المستقبل.');
    }

    /**
     * @return array<string, mixed>
     */
    private function payloadAt(string $cairoLocal): array
    {
        return $this->payloadIso(Carbon::parse($cairoLocal, 'Africa/Cairo')->toAtomString());
    }

    /**
     * @return array<string, mixed>
     */
    private function payloadIso(string $iso): array
    {
        $payload = $this->tripRequestPayload();
        $payload['requested_at'] = $iso;

        return $payload;
    }
}
