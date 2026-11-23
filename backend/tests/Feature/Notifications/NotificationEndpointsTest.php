<?php

declare(strict_types=1);

namespace Tests\Feature\Notifications;

use App\Domain\Enums\NotificationType;
use App\Domain\Enums\UserRole;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class NotificationEndpointsTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    public function test_notification_routes_require_authentication(): void
    {
        $this->getJson('/api/notifications')->assertUnauthorized();
        $this->getJson('/api/notifications/unread-count')->assertUnauthorized();
        $this->postJson('/api/notifications/read-all')->assertUnauthorized();
        $this->postJson('/api/notifications/'.fake()->uuid().'/read')->assertUnauthorized();
    }

    public function test_list_is_paginated_and_filters_unread(): void
    {
        [$owner, $first, $second] = $this->twoNotifications();

        Sanctum::actingAs($owner);
        $this->getJson('/api/notifications?per_page=1')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('meta.per_page', 1)
            ->assertJsonPath('meta.current_page', 1)
            ->assertJsonPath('data.0.id', $second->id);

        $this->getJson('/api/notifications?unread=true')
            ->assertOk()
            ->assertJsonCount(2, 'data');

        $this->postJson('/api/notifications/'.$first->id.'/read')->assertOk();

        $this->getJson('/api/notifications?unread=true')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $second->id);

        $this->getJson('/api/notifications?unread=false')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $first->id);

        $this->getJson('/api/notifications?unread=maybe')->assertStatus(422);
    }

    public function test_unread_count_read_and_read_all_are_scoped_to_the_caller(): void
    {
        [$owner, $first, $second] = $this->twoNotifications();
        $other = $this->createUserWithRole(UserRole::CompanyAdmin);

        Sanctum::actingAs($owner);
        $this->getJson('/api/notifications/unread-count')->assertOk()->assertJsonPath('count', 2);

        $this->travelTo(Carbon::parse('2026-11-16 10:00:00', 'UTC'));
        $readAt = $this->postJson('/api/notifications/'.$first->id.'/read')
            ->assertOk()
            ->assertJsonPath('type', NotificationType::RequestSubmitted->value)
            ->json('read_at');
        $this->assertNotNull($readAt);

        $this->travelTo(Carbon::parse('2026-11-16 12:00:00', 'UTC'));
        $this->postJson('/api/notifications/'.$first->id.'/read')
            ->assertOk()
            ->assertJsonPath('read_at', $readAt);

        $this->getJson('/api/notifications/unread-count')->assertOk()->assertJsonPath('count', 1);

        $this->postJson('/api/notifications/read-all')
            ->assertOk()
            ->assertJsonPath('updated', 1);

        $this->assertSame($readAt, $first->fresh()->read_at?->format(DATE_ATOM));
        $this->assertNotNull($second->fresh()->read_at);
        $this->getJson('/api/notifications/unread-count')->assertOk()->assertJsonPath('count', 0);

        Sanctum::actingAs($other);
        $this->getJson('/api/notifications')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/notifications/unread-count')->assertOk()->assertJsonPath('count', 0);
    }

    public function test_reading_another_users_notification_is_forbidden(): void
    {
        [$owner, $notification] = $this->oneNotification();
        $employee = $this->createUserWithRole(UserRole::Employee);
        $otherAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);

        Sanctum::actingAs($employee);
        $this->postJson('/api/notifications/'.$notification->id.'/read')->assertForbidden();

        Sanctum::actingAs($otherAdmin);
        $this->postJson('/api/notifications/'.$notification->id.'/read')->assertForbidden();

        $this->postJson('/api/notifications/'.fake()->uuid().'/read')->assertNotFound();

        $this->assertNull($notification->fresh()->read_at);
        $this->assertSame($owner->id, $notification->user_id);
    }

    public function test_read_all_does_not_mark_another_users_rows(): void
    {
        [$owner, $owned] = $this->oneNotification();
        $other = $this->createUserWithRole(UserRole::CompanyAdmin);
        $foreign = Notification::query()->create([
            'user_id' => $other->id,
            'type' => NotificationType::TripReadyToAssign,
            'title_key' => NotificationType::TripReadyToAssign->titleKey(),
            'body_key' => NotificationType::TripReadyToAssign->bodyKey(),
            'params' => ['pickup' => 'A', 'destination' => 'B'],
        ]);

        Sanctum::actingAs($owner);
        $this->postJson('/api/notifications/read-all')->assertOk()->assertJsonPath('updated', 1);

        $this->assertNotNull($owned->fresh()->read_at);
        $this->assertNull($foreign->fresh()->read_at);
    }

    /**
     * @return array{0: User, 1: Notification, 2: Notification}
     */
    private function twoNotifications(): array
    {
        $firstAdmin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $this->createUserWithRole(UserRole::CompanyAdmin);
        $employee = $this->createUserWithRole(UserRole::Employee);

        Sanctum::actingAs($employee);
        $this->postJson('/api/trip-requests', $this->tripRequestPayload())->assertCreated();
        $this->postJson('/api/trip-requests', $this->tripRequestPayload())->assertCreated();

        $rows = Notification::query()
            ->where('user_id', $firstAdmin->id)
            ->orderBy('created_at')
            ->orderBy('id')
            ->get();

        $this->assertCount(2, $rows);

        return [$firstAdmin, $rows[0], $rows[1]];
    }

    /**
     * @return array{0: User, 1: Notification}
     */
    private function oneNotification(): array
    {
        $admin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $employee = $this->createUserWithRole(UserRole::Employee);

        Sanctum::actingAs($employee);
        $this->postJson('/api/trip-requests', $this->tripRequestPayload())->assertCreated();

        $notification = Notification::query()->where('user_id', $admin->id)->firstOrFail();

        return [$admin, $notification];
    }
}
