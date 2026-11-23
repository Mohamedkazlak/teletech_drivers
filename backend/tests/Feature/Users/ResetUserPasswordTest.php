<?php

declare(strict_types=1);

namespace Tests\Feature\Users;

use App\Domain\Enums\UserRole;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class ResetUserPasswordTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_admin_lists_every_role(): void
    {
        foreach (UserRole::cases() as $role) {
            $this->createUserWithRole($role);
        }

        $response = $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/users')
            ->assertOk();

        $roles = collect($response->json('data'))->pluck('role')->unique()->sort()->values()->all();
        $expected = collect(UserRole::cases())->map(fn (UserRole $role): string => $role->value)->sort()->values()->all();

        $this->assertSame($expected, $roles);
        $this->assertSame(count(UserRole::cases()) + 1, $response->json('meta.total'));
    }

    public function test_admin_can_search_by_email(): void
    {
        $target = User::factory()->companyAdmin()->create([
            'email' => 'fleet.lead@example.com',
            'name_en' => 'Fleet Lead',
        ]);
        User::factory()->employee()->create(['email' => 'other@example.com']);

        $this->actingAsRole(UserRole::Admin)
            ->getJson('/api/users?search=fleet.lead')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $target->id);
    }

    /**
     * @return list<array{0: UserRole}>
     */
    public static function resettableRoles(): array
    {
        return [
            [UserRole::Admin],
            [UserRole::CompanyAdmin],
            [UserRole::DriversAdmin],
            [UserRole::Driver],
            [UserRole::Employee],
        ];
    }

    #[DataProvider('resettableRoles')]
    public function test_admin_reset_forces_a_change_on_next_sign_in(UserRole $role): void
    {
        $target = User::factory()->state(['role' => $role])->create([
            'email' => 'reset-'.$role->value.'@example.com',
            'password' => Hash::make('password123'),
            'must_change_password' => false,
        ]);
        $target->createToken('mobile');

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/users/'.$target->id.'/reset-password', [
                'password' => 'temporary1',
                'password_confirmation' => 'temporary1',
            ])
            ->assertOk()
            ->assertJsonPath('id', $target->id)
            ->assertJsonPath('must_change_password', true);

        $target->refresh();
        $this->assertTrue($target->must_change_password);
        $this->assertTrue(Hash::check('temporary1', $target->password));
        $this->assertSame(0, $target->tokens()->count());

        $this->flushHeaders();
        $this->app['auth']->forgetGuards();

        $this->postJson('/api/auth/login', [
            'email' => $target->email,
            'password' => 'password123',
        ])->assertUnauthorized();

        $login = $this->postJson('/api/auth/login', [
            'email' => $target->email,
            'password' => 'temporary1',
        ])->assertOk();

        $this->assertTrue($login->json('user.must_change_password'));

        $this->withToken($login->json('token'))
            ->postJson('/api/auth/change-password', [
                'current_password' => 'temporary1',
                'password' => 'chosenpass1',
                'password_confirmation' => 'chosenpass1',
            ])
            ->assertOk()
            ->assertJsonPath('must_change_password', false);

        $this->flushHeaders();
        $this->app['auth']->forgetGuards();

        $this->postJson('/api/auth/login', [
            'email' => $target->email,
            'password' => 'chosenpass1',
        ])->assertOk()
            ->assertJsonPath('user.must_change_password', false);
    }

    public function test_admin_cannot_reset_their_own_password(): void
    {
        $admin = $this->createUserWithRole(UserRole::Admin);

        $this->actingAs($admin, 'sanctum')
            ->postJson('/api/users/'.$admin->id.'/reset-password', [
                'password' => 'temporary1',
                'password_confirmation' => 'temporary1',
            ])
            ->assertStatus(422);
    }

    public function test_deleted_user_cannot_be_reset(): void
    {
        $employee = User::factory()->employee()->create();
        $employee->delete();

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/users/'.$employee->id.'/reset-password', [
                'password' => 'temporary1',
                'password_confirmation' => 'temporary1',
            ])
            ->assertNotFound();
    }

    public function test_short_password_is_rejected(): void
    {
        $employee = User::factory()->employee()->create();

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/users/'.$employee->id.'/reset-password', [
                'password' => 'short',
                'password_confirmation' => 'short',
            ])
            ->assertStatus(422);
    }

    /**
     * @return list<array{0: UserRole}>
     */
    public static function forbiddenRoles(): array
    {
        return [
            [UserRole::CompanyAdmin],
            [UserRole::DriversAdmin],
            [UserRole::Driver],
            [UserRole::Employee],
        ];
    }

    #[DataProvider('forbiddenRoles')]
    public function test_non_admins_cannot_list_or_reset_users(UserRole $role): void
    {
        $employee = User::factory()->employee()->create();

        $this->actingAsRole($role)->getJson('/api/users')->assertForbidden();

        $this->actingAsRole($role)
            ->postJson('/api/users/'.$employee->id.'/reset-password', [
                'password' => 'temporary1',
                'password_confirmation' => 'temporary1',
            ])
            ->assertForbidden();
    }

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/users')->assertUnauthorized();
        $this->postJson('/api/users/'.fake()->uuid().'/reset-password', [])->assertUnauthorized();
    }
}
