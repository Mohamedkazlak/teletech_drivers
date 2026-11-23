<?php

declare(strict_types=1);

namespace Tests\Feature\Push;

use App\Domain\Enums\UserRole;
use App\Models\DeviceToken;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class DeviceTokenTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_device_token_routes_require_authentication(): void
    {
        $this->postJson('/api/device-tokens', [
            'token' => 'abc',
            'platform' => 'android',
        ])->assertUnauthorized();

        $this->deleteJson('/api/device-tokens', [
            'token' => 'abc',
        ])->assertUnauthorized();
    }

    public function test_upsert_updates_the_same_token_and_reassigns_it_to_another_user(): void
    {
        $first = $this->createUserWithRole(UserRole::Employee);
        $second = $this->createUserWithRole(UserRole::Driver);

        Sanctum::actingAs($first);
        $this->postJson('/api/device-tokens', [
            'token' => 'shared-token',
            'platform' => 'android',
        ])->assertNoContent();

        $this->assertDatabaseHas('device_tokens', [
            'token' => 'shared-token',
            'user_id' => $first->id,
            'platform' => 'android',
            'locale' => 'en',
        ]);
        $this->assertNotNull(DeviceToken::query()->where('token', 'shared-token')->value('last_seen_at'));

        $this->postJson('/api/device-tokens', [
            'token' => 'shared-token',
            'platform' => 'ios',
        ])->assertNoContent();

        $this->assertSame(1, DeviceToken::query()->where('token', 'shared-token')->count());
        $this->assertDatabaseHas('device_tokens', [
            'token' => 'shared-token',
            'user_id' => $first->id,
            'platform' => 'ios',
        ]);

        Sanctum::actingAs($second);
        $this->withHeader('Accept-Language', 'ar')
            ->postJson('/api/device-tokens', [
                'token' => 'shared-token',
                'platform' => 'android',
            ])
            ->assertNoContent();

        $this->assertSame(1, DeviceToken::query()->count());
        $this->assertDatabaseHas('device_tokens', [
            'token' => 'shared-token',
            'user_id' => $second->id,
            'platform' => 'android',
            'locale' => 'ar',
        ]);
    }

    public function test_delete_removes_only_the_caller_token(): void
    {
        $owner = $this->createUserWithRole(UserRole::Employee);
        $other = $this->createUserWithRole(UserRole::Driver);
        DeviceToken::query()->create([
            'user_id' => $owner->id,
            'token' => 'owner-token',
            'platform' => 'android',
            'locale' => 'en',
            'last_seen_at' => now(),
        ]);
        DeviceToken::query()->create([
            'user_id' => $other->id,
            'token' => 'other-token',
            'platform' => 'ios',
            'locale' => 'en',
            'last_seen_at' => now(),
        ]);

        Sanctum::actingAs($owner);
        $this->deleteJson('/api/device-tokens', ['token' => 'other-token'])->assertNoContent();
        $this->assertDatabaseHas('device_tokens', ['token' => 'other-token']);

        $this->deleteJson('/api/device-tokens', ['token' => 'owner-token'])->assertNoContent();
        $this->assertDatabaseMissing('device_tokens', ['token' => 'owner-token']);
        $this->deleteJson('/api/device-tokens', ['token' => 'owner-token'])->assertNoContent();
    }

    public function test_platform_must_be_android_or_ios(): void
    {
        Sanctum::actingAs($this->createUserWithRole(UserRole::Employee));

        $this->postJson('/api/device-tokens', [
            'token' => 'abc',
            'platform' => 'web',
        ])->assertStatus(422);
    }
}
