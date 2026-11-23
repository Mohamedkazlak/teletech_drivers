<?php

declare(strict_types=1);

namespace App\Domain\Repositories;

use App\Domain\Entities\User;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Domain\Shared\PaginatedResult;

interface UserRepositoryInterface
{
    public function findById(string $id, bool $withTrashed = false): ?User;

    public function findByEmail(string $email): ?User;

    public function createEmployee(
        string $nameEn,
        ?string $nameAr,
        string $email,
        string $passwordHash,
        ?string $phone,
        ?Branch $branch,
        bool $mustChangePassword = false,
    ): User;

    /**
     * Merges only the provided profile fields. Omitted keys are left unchanged.
     * role and is_active are ignored.
     *
     * @param  array<string, mixed>  $changes
     */
    public function updateProfile(string $id, array $changes): User;

    public function updatePassword(string $id, string $passwordHash): User;

    /**
     * Replaces the password and requires a change on the next sign-in.
     */
    public function assignTemporaryPassword(string $id, string $passwordHash): User;

    /**
     * Active directory of every non-deleted account, any role.
     *
     * @return PaginatedResult<User>
     */
    public function paginateUsers(
        ?UserRole $role,
        ?string $search,
        int $page,
        int $perPage,
    ): PaginatedResult;

    public function createWithRole(
        string $nameEn,
        ?string $nameAr,
        string $email,
        string $passwordHash,
        UserRole $role,
        ?string $phone = null,
        ?Branch $branch = null,
        bool $mustChangePassword = false,
    ): User;

    /**
     * @return PaginatedResult<User>
     */
    public function paginateEmployees(
        ?bool $isActive,
        ?Branch $branch,
        ?string $search,
        bool $includeDeleted,
        int $page,
        int $perPage,
    ): PaginatedResult;

    public function updateEmployee(
        string $id,
        string $nameEn,
        ?string $nameAr,
        ?string $phone,
        ?Branch $branch,
        bool $isActive,
        ?string $passwordHash,
    ): User;

    public function softDelete(string $id, string $deletedBy): User;

    public function restore(string $id): User;

    /**
     * Active, non-deleted users with this role.
     *
     * @return list<string>
     */
    public function activeIdsForRole(UserRole $role): array;
}
