<?php

declare(strict_types=1);

namespace Tests\Feature\Employees;

use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Models\User;
use App\Policies\UserPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class EmployeeEndpointsTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    /**
     * @return array{name_en: string, name_ar: string, email: string, password: string, phone: string, branch: string}
     */
    private function employeePayload(string $email = 'newemp@example.com'): array
    {
        return [
            'name_en' => 'New Employee',
            'name_ar' => 'موظف جديد',
            'email' => $email,
            'password' => 'password123',
            'phone' => '01099998888',
            'branch' => Branch::CompanyHeadquarters->value,
        ];
    }

    public function test_admin_created_employee_must_change_password(): void
    {
        $response = $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/employees', $this->employeePayload())
            ->assertCreated();

        $employee = User::query()->findOrFail($response->json('id'));
        $this->assertTrue($employee->must_change_password);
        $this->assertSame(Branch::CompanyHeadquarters, $employee->branch);
    }

    public function test_unauthenticated_returns_401(): void
    {
        $this->getJson('/api/employees')->assertUnauthorized();
        $this->postJson('/api/employees', [])->assertUnauthorized();
    }

    /**
     * @return list<array{0: UserRole, 1: int}>
     */
    public static function listRoleMatrix(): array
    {
        return [
            [UserRole::Admin, 200],
            [UserRole::CompanyAdmin, 200],
            [UserRole::DriversAdmin, 403],
            [UserRole::Driver, 403],
            [UserRole::Employee, 403],
        ];
    }

    #[DataProvider('listRoleMatrix')]
    public function test_list_employees_role_matrix(UserRole $role, int $status): void
    {
        User::factory()->employee()->create();

        $this->actingAsRole($role)
            ->getJson('/api/employees')
            ->assertStatus($status);
    }

    /**
     * @return list<array{0: UserRole, 1: int}>
     */
    public static function writeRoleMatrix(): array
    {
        return [
            [UserRole::Admin, 201],
            [UserRole::CompanyAdmin, 403],
            [UserRole::DriversAdmin, 403],
            [UserRole::Driver, 403],
            [UserRole::Employee, 403],
        ];
    }

    #[DataProvider('writeRoleMatrix')]
    public function test_create_employee_role_matrix(UserRole $role, int $status): void
    {
        $this->actingAsRole($role)
            ->postJson('/api/employees', $this->employeePayload(
                email: 'emp-'.$role->value.'@example.com',
            ))
            ->assertStatus($status);
    }

    /**
     * @return list<array{0: UserRole, 1: int}>
     */
    public static function mutateRoleMatrix(): array
    {
        return [
            [UserRole::Admin, 200],
            [UserRole::CompanyAdmin, 403],
            [UserRole::DriversAdmin, 403],
            [UserRole::Driver, 403],
            [UserRole::Employee, 403],
        ];
    }

    #[DataProvider('mutateRoleMatrix')]
    public function test_update_employee_role_matrix(UserRole $role, int $status): void
    {
        $employee = User::factory()->employee()->create();

        $this->actingAsRole($role)
            ->patchJson('/api/employees/'.$employee->id, [
                'name_en' => 'Updated',
                'name_ar' => 'محدث',
                'phone' => '010',
                'branch' => Branch::NewHeadquarters->value,
                'is_active' => true,
            ])
            ->assertStatus($status);
    }

    public function test_policy_denies_acting_on_self(): void
    {
        $admin = User::factory()->admin()->create();
        // Simulate target with same id but employee role for policy check.
        $selfAsEmployee = User::factory()->employee()->make(['id' => $admin->id]);
        $selfAsEmployee->id = $admin->id;

        $policy = new UserPolicy;

        $this->assertFalse($policy->updateEmployee($admin, $selfAsEmployee));
        $this->assertFalse($policy->deleteEmployee($admin, $selfAsEmployee));
        $this->assertFalse($policy->restoreEmployee($admin, $selfAsEmployee));
    }

    public function test_policy_denies_driver_self_mutation(): void
    {
        $driver = User::factory()->driver()->create();
        $policy = new UserPolicy;

        $this->assertFalse($policy->updateDriver($driver, $driver));
        $this->assertFalse($policy->deleteDriver($driver, $driver));
    }

    public function test_soft_delete_and_restore(): void
    {
        $employee = User::factory()->employee()->create();
        $token = $employee->createToken('auth');
        $tokenId = $token->accessToken->id;

        $this->actingAsRole(UserRole::Admin)
            ->deleteJson('/api/employees/'.$employee->id)
            ->assertOk()
            ->assertJsonPath('is_active', false);

        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $tokenId]);
        $this->assertSoftDeleted('users', ['id' => $employee->id]);

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/employees/'.$employee->id.'/restore')
            ->assertOk()
            ->assertJsonPath('is_active', true);
    }

    public function test_email_immutable_on_update(): void
    {
        $employee = User::factory()->employee()->create([
            'email' => 'keep@example.com',
        ]);

        $this->actingAsRole(UserRole::Admin)
            ->patchJson('/api/employees/'.$employee->id, [
                'name_en' => 'Keep Email',
                'name_ar' => 'ك',
                'phone' => null,
                'branch' => Branch::NewHeadquarters->value,
                'is_active' => true,
                'email' => 'changed@example.com',
                'role' => 'admin',
            ])
            ->assertOk()
            ->assertJsonPath('email', 'keep@example.com')
            ->assertJsonPath('role', UserRole::Employee->value);
    }

    public function test_duplicate_email_on_create(): void
    {
        User::factory()->employee()->create(['email' => 'dup@example.com']);

        $this->actingAsRole(UserRole::Admin)
            ->postJson('/api/employees', $this->employeePayload('dup@example.com'))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_admin_branch_change_is_visible_on_the_employee_profile(): void
    {
        $employee = User::factory()->employee()->create([
            'branch' => Branch::CompanyHeadquarters,
        ]);

        $this->actingAsRole(UserRole::Admin)
            ->patchJson('/api/employees/'.$employee->id, [
                'branch' => Branch::NewHeadquarters->value,
            ])
            ->assertOk()
            ->assertJsonPath('branch', Branch::NewHeadquarters->value);

        $this->actingAs($employee, 'sanctum')
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('branch', Branch::NewHeadquarters->value);

        $this->actingAsRole(UserRole::CompanyAdmin)
            ->patchJson('/api/employees/'.$employee->id, [
                'branch' => Branch::CompanyHeadquarters->value,
            ])
            ->assertForbidden();

        $employee->refresh();
        $this->assertSame(Branch::NewHeadquarters, $employee->branch);
    }

    public function test_self_registration_still_works(): void
    {
        $this->postJson('/api/auth/register', [
            'name_en' => 'Self',
            'name_ar' => 'ذاتي',
            'email' => 'selfreg@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'phone' => '01000000000',
            'branch' => Branch::CompanyHeadquarters->value,
        ])
            ->assertCreated()
            ->assertJsonPath('user.role', UserRole::Employee->value)
            ->assertJsonPath('user.must_change_password', false);
    }
}
