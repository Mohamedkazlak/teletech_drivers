<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

final class UuidTokenTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_issues_token_for_uuid_user_and_token_works(): void
    {
        $user = User::factory()->employee()->create([
            'email' => 'uuid-user@example.com',
            'password' => Hash::make('password123'),
        ]);

        $this->assertTrue(Str::isUuid($user->id));

        $login = $this->postJson('/api/auth/login', [
            'email' => 'uuid-user@example.com',
            'password' => 'password123',
        ])->assertOk();

        $token = $login->json('token');
        $this->assertIsString($token);

        $accessToken = PersonalAccessToken::findToken($token);
        $this->assertNotNull($accessToken);
        $this->assertTrue(Str::isUuid((string) $accessToken->tokenable_id));
        $this->assertSame($user->id, (string) $accessToken->tokenable_id);

        $this->withToken($token)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('id', $user->id);
    }
}
