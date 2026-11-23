<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Http\Middleware\EnsurePasswordChangeNotRequired;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Route;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

final class AuthEndpointsTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_creates_employee_only(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name_en' => 'Jane Doe',
            'name_ar' => 'جين',
            'email' => 'jane@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'phone' => '01000000000',
            'branch' => Branch::CompanyHeadquarters->value,
        ]);

        $response->assertCreated()
            ->assertJsonPath('user.role', UserRole::Employee->value)
            ->assertJsonPath('user.email', 'jane@example.com')
            ->assertJsonPath('user.branch', Branch::CompanyHeadquarters->value)
            ->assertJsonPath('user.must_change_password', false)
            ->assertJsonMissingPath('user.password')
            ->assertJsonStructure(['token', 'token_type', 'user' => ['id', 'name_en', 'role']]);

        $this->assertDatabaseHas('users', [
            'email' => 'jane@example.com',
            'role' => UserRole::Employee->value,
        ]);
    }

    public function test_login_works_for_active_user(): void
    {
        User::factory()->employee()->create([
            'email' => 'jane@example.com',
            'password' => Hash::make('password123'),
        ]);

        $this->postJson('/api/auth/login', [
            'email' => 'jane@example.com',
            'password' => 'password123',
        ])
            ->assertOk()
            ->assertJsonPath('user.must_change_password', false)
            ->assertJsonStructure(['token', 'user']);
    }

    public function test_inactive_user_cannot_login(): void
    {
        User::factory()->employee()->inactive()->create([
            'email' => 'inactive@example.com',
            'password' => Hash::make('password123'),
        ]);

        $this->postJson('/api/auth/login', [
            'email' => 'inactive@example.com',
            'password' => 'password123',
        ])->assertUnauthorized();
    }

    public function test_me_hides_password(): void
    {
        $user = User::factory()->employee()->create([
            'password' => Hash::make('password123'),
        ]);

        $token = $user->createToken('auth')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('email', $user->email)
            ->assertJsonMissingPath('password')
            ->assertJsonMissing(['password']);
    }

    public function test_unauthenticated_me_returns_401(): void
    {
        $this->getJson('/api/auth/me')->assertUnauthorized();
    }

    public function test_revoked_token_returns_401_on_me(): void
    {
        $user = User::factory()->employee()->create();
        $accessToken = $user->createToken('auth');
        $plain = $accessToken->plainTextToken;
        $accessToken->accessToken->delete();

        $this->withToken($plain)
            ->getJson('/api/auth/me')
            ->assertUnauthorized();
    }

    public function test_expired_token_returns_401_on_me(): void
    {
        $user = User::factory()->employee()->create();
        $accessToken = $user->createToken('auth');
        $plain = $accessToken->plainTextToken;

        PersonalAccessToken::query()
            ->where('id', $accessToken->accessToken->id)
            ->update(['expires_at' => now()->subMinute()]);

        $this->withToken($plain)
            ->getJson('/api/auth/me')
            ->assertUnauthorized();
    }

    public function test_role_middleware_returns_403(): void
    {
        Route::middleware(['api', 'auth:sanctum', 'role:company_admin,drivers_admin'])
            ->get('/api/__test/role-check', fn () => response()->json(['ok' => true]));

        $employee = User::factory()->employee()->create();

        $this->actingAs($employee, 'sanctum')
            ->getJson('/api/__test/role-check')
            ->assertForbidden()
            ->assertJsonPath('message', 'Forbidden.');

        $admin = User::factory()->companyAdmin()->create();

        $this->assertSame(UserRole::CompanyAdmin, $admin->role);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/__test/role-check')
            ->assertOk();
    }

    public function test_update_me_merges_present_fields_only(): void
    {
        $user = User::factory()->employee()->create([
            'email' => 'jane@example.com',
            'name_en' => 'Old',
            'name_ar' => 'قديم',
            'phone' => '010',
            'branch' => Branch::CompanyHeadquarters,
            'is_active' => true,
        ]);
        $token = $user->createToken('auth')->plainTextToken;

        $this->withToken($token)
            ->patchJson('/api/auth/me', [
                'name_en' => 'New Name',
                'phone' => '015',
                'role' => 'admin',
                'is_active' => false,
            ])
            ->assertOk()
            ->assertJsonPath('name_en', 'New Name')
            ->assertJsonPath('name_ar', 'قديم')
            ->assertJsonPath('phone', '015')
            ->assertJsonPath('branch', Branch::CompanyHeadquarters->value)
            ->assertJsonPath('email', 'jane@example.com')
            ->assertJsonPath('role', UserRole::Employee->value)
            ->assertJsonPath('is_active', true);

        $this->withToken($token)
            ->patchJson('/api/auth/me', [
                'email' => 'jane.new@example.com',
            ])
            ->assertOk()
            ->assertJsonPath('email', 'jane.new@example.com')
            ->assertJsonPath('name_ar', 'قديم')
            ->assertJsonPath('name_en', 'New Name');

        User::factory()->employee()->create(['email' => 'taken@example.com']);

        $this->withToken($token)
            ->patchJson('/api/auth/me', [
                'email' => 'taken@example.com',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_non_admin_cannot_change_branch_after_registration(): void
    {
        foreach ([UserRole::Employee, UserRole::CompanyAdmin, UserRole::DriversAdmin, UserRole::Driver] as $role) {
            $user = User::factory()->create([
                'role' => $role,
                'branch' => Branch::CompanyHeadquarters,
            ]);

            $this->actingAs($user, 'sanctum')
                ->patchJson('/api/auth/me', [
                    'branch' => Branch::NewHeadquarters->value,
                ])
                ->assertStatus(422)
                ->assertJsonValidationErrors(['branch'])
                ->assertJsonPath('errors.branch.0', 'Only an admin can change the branch after registration.');

            $user->refresh();
            $this->assertSame(Branch::CompanyHeadquarters, $user->branch);
        }
    }

    public function test_admin_can_change_own_branch(): void
    {
        $admin = User::factory()->admin()->create([
            'branch' => Branch::CompanyHeadquarters,
        ]);

        $this->actingAs($admin, 'sanctum')
            ->patchJson('/api/auth/me', [
                'branch' => Branch::NewHeadquarters->value,
            ])
            ->assertOk()
            ->assertJsonPath('branch', Branch::NewHeadquarters->value);
    }

    public function test_logout_revokes_token(): void
    {
        $user = User::factory()->employee()->create();
        $newAccessToken = $user->createToken('auth');
        $token = $newAccessToken->plainTextToken;
        $tokenId = $newAccessToken->accessToken->id;

        $this->withToken($token)
            ->postJson('/api/auth/logout')
            ->assertOk();

        $this->assertDatabaseMissing('personal_access_tokens', [
            'id' => $tokenId,
        ]);

        $this->app['auth']->forgetGuards();

        $this->withToken($token)
            ->getJson('/api/auth/me')
            ->assertUnauthorized();
    }

    public function test_me_includes_derived_availability(): void
    {
        $user = User::factory()->employee()->create();
        $token = $user->createToken('auth')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('is_available', false)
            ->assertJsonMissingPath('availability_status')
            ->assertJsonMissingPath('password');

        $this->app['auth']->forgetGuards();

        $driver = User::factory()->driver()->create();

        $this->withToken($driver->createToken('auth')->plainTextToken)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('is_available', false)
            ->assertJsonPath('role', UserRole::Driver->value);
    }

    public function test_change_password_keeps_current_token_and_revokes_others(): void
    {
        $user = User::factory()->employee()->create([
            'password' => Hash::make('password123'),
        ]);
        $current = $user->createToken('phone');
        $other = $user->createToken('tablet');

        $this->withToken($current->plainTextToken)
            ->postJson('/api/auth/change-password', [
                'current_password' => 'password123',
                'password' => 'newpassword123',
                'password_confirmation' => 'newpassword123',
            ])
            ->assertOk()
            ->assertJsonPath('id', $user->id)
            ->assertJsonPath('email', $user->email)
            ->assertJsonPath('must_change_password', false)
            ->assertJsonMissingPath('message');

        $user->refresh();
        $this->assertTrue(Hash::check('newpassword123', $user->password));
        $this->assertFalse(Hash::check('password123', $user->password));
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $other->accessToken->id]);
        $this->assertDatabaseHas('personal_access_tokens', ['id' => $current->accessToken->id]);

        $this->withToken($current->plainTextToken)
            ->getJson('/api/auth/me')
            ->assertOk();

        $this->app['auth']->forgetGuards();

        $this->withToken($other->plainTextToken)
            ->getJson('/api/auth/me')
            ->assertUnauthorized();
    }

    public function test_change_password_rejects_wrong_current_password(): void
    {
        $user = User::factory()->driver()->create([
            'password' => Hash::make('password123'),
        ]);
        $token = $user->createToken('auth');

        $this->withToken($token->plainTextToken)
            ->postJson('/api/auth/change-password', [
                'current_password' => 'wrong-password',
                'password' => 'newpassword123',
                'password_confirmation' => 'newpassword123',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['current_password']);

        $user->refresh();
        $this->assertTrue(Hash::check('password123', $user->password));
        $this->assertDatabaseHas('personal_access_tokens', ['id' => $token->accessToken->id]);
    }

    public function test_change_password_rejects_weak_or_mismatched_password(): void
    {
        $user = User::factory()->companyAdmin()->create([
            'password' => Hash::make('password123'),
        ]);
        $token = $user->createToken('auth')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/auth/change-password', [
                'current_password' => 'password123',
                'password' => 'short',
                'password_confirmation' => 'short',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['password']);

        $this->withToken($token)
            ->postJson('/api/auth/change-password', [
                'current_password' => 'password123',
                'password' => 'newpassword123',
                'password_confirmation' => 'different123',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['password']);

        $user->refresh();
        $this->assertTrue(Hash::check('password123', $user->password));
    }

    public function test_change_password_requires_authentication(): void
    {
        $this->postJson('/api/auth/change-password', [
            'current_password' => 'password123',
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ])->assertUnauthorized();
    }

    public function test_register_requires_arabic_name_phone_branch_and_password_confirmation(): void
    {
        $this->postJson('/api/auth/register', [
            'name_en' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => 'password123',
            'branch' => 'headquarters',
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['name_ar', 'phone', 'branch', 'password']);

        $this->postJson('/api/auth/register', [
            'name_en' => 'Jane Doe',
            'name_ar' => 'جين',
            'email' => 'jane2@example.com',
            'password' => 'password123',
            'password_confirmation' => 'different123',
            'phone' => '01000000000',
            'branch' => 'villa',
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['password', 'branch']);
    }

    public function test_me_returns_must_change_password(): void
    {
        $user = User::factory()->employee()->create([
            'must_change_password' => true,
        ]);

        $this->withToken($user->createToken('auth')->plainTextToken)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('must_change_password', true);
    }

    public function test_forced_password_change_blocks_other_routes_until_changed(): void
    {
        $user = User::factory()->employee()->create([
            'password' => Hash::make('password123'),
            'must_change_password' => true,
        ]);
        $token = $user->createToken('auth')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/places')
            ->assertForbidden()
            ->assertJsonPath('code', EnsurePasswordChangeNotRequired::CODE)
            ->assertJsonPath('message', EnsurePasswordChangeNotRequired::MESSAGE);

        $this->withToken($token)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('must_change_password', true);

        $this->withToken($token)
            ->patchJson('/api/auth/me', [
                'name_en' => 'Still Allowed',
            ])
            ->assertOk()
            ->assertJsonPath('name_en', 'Still Allowed');

        $this->withToken($token)
            ->postJson('/api/auth/change-password', [
                'current_password' => 'password123',
                'password' => 'newpassword123',
                'password_confirmation' => 'newpassword123',
            ])
            ->assertOk();

        $user->refresh();
        $this->assertFalse($user->must_change_password);

        $this->app['auth']->forgetGuards();

        $this->withToken($token)
            ->getJson('/api/places')
            ->assertOk();

        $this->withToken($token)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('must_change_password', false);
    }

    public function test_forced_password_change_still_allows_logout(): void
    {
        $user = User::factory()->driver()->create([
            'must_change_password' => true,
        ]);
        $token = $user->createToken('auth')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/auth/me/driver-profile')
            ->assertForbidden()
            ->assertJsonPath('code', EnsurePasswordChangeNotRequired::CODE);

        $this->withToken($token)
            ->postJson('/api/auth/logout')
            ->assertOk();
    }
}
