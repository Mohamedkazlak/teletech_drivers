<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\UserRepositoryInterface;
use App\Domain\Shared\PaginatedResult;
use Illuminate\Support\Str;

final class FakeUserRepository implements UserRepositoryInterface
{
    /** @var array<string, User> */
    private array $byId = [];

    /** @var array<string, string> */
    private array $emailIndex = [];

    public function findById(string $id, bool $withTrashed = false): ?User
    {
        $user = $this->byId[$id] ?? null;

        if ($user === null) {
            return null;
        }

        if (! $withTrashed && $user->isSoftDeleted()) {
            return null;
        }

        return $user;
    }

    public function findByEmail(string $email): ?User
    {
        $id = $this->emailIndex[strtolower($email)] ?? null;

        if ($id === null) {
            return null;
        }

        $user = $this->byId[$id] ?? null;

        if ($user === null || $user->isSoftDeleted()) {
            return null;
        }

        return $user;
    }

    public function createEmployee(
        string $nameEn,
        ?string $nameAr,
        string $email,
        string $passwordHash,
        ?string $phone,
        ?Branch $branch,
        bool $mustChangePassword = false,
    ): User {
        return $this->createWithRole(
            nameEn: $nameEn,
            nameAr: $nameAr,
            email: $email,
            passwordHash: $passwordHash,
            role: UserRole::Employee,
            phone: $phone,
            branch: $branch,
            mustChangePassword: $mustChangePassword,
        );
    }

    public function updateProfile(string $id, array $changes): User
    {
        $existing = $this->findById($id);

        if ($existing === null) {
            throw new UserNotFoundException;
        }

        $allowed = array_intersect_key($changes, array_flip([
            'name_en',
            'name_ar',
            'phone',
            'branch',
            'email',
        ]));

        $email = array_key_exists('email', $allowed) ? (string) $allowed['email'] : $existing->email;
        if ($email !== $existing->email) {
            unset($this->emailIndex[strtolower($existing->email)]);
            $this->emailIndex[strtolower($email)] = $existing->id;
        }

        $updated = new User(
            id: $existing->id,
            nameEn: array_key_exists('name_en', $allowed) ? (string) $allowed['name_en'] : $existing->nameEn,
            nameAr: array_key_exists('name_ar', $allowed) ? $allowed['name_ar'] : $existing->nameAr,
            email: $email,
            passwordHash: $existing->passwordHash,
            role: $existing->role,
            isActive: $existing->isActive,
            phone: array_key_exists('phone', $allowed) ? $allowed['phone'] : $existing->phone,
            branch: array_key_exists('branch', $allowed) ? $allowed['branch'] : $existing->branch,
            availabilityStatus: $existing->availabilityStatus,
            availabilityUpdatedAt: $existing->availabilityUpdatedAt,
            deletedAt: $existing->deletedAt,
            deletedBy: $existing->deletedBy,
            mustChangePassword: $existing->mustChangePassword,
        );

        $this->byId[$id] = $updated;

        return $updated;
    }

    public function updatePassword(string $id, string $passwordHash): User
    {
        $existing = $this->findById($id);

        if ($existing === null) {
            throw new UserNotFoundException;
        }

        $updated = new User(
            id: $existing->id,
            nameEn: $existing->nameEn,
            nameAr: $existing->nameAr,
            email: $existing->email,
            passwordHash: $passwordHash,
            role: $existing->role,
            isActive: $existing->isActive,
            phone: $existing->phone,
            branch: $existing->branch,
            availabilityStatus: $existing->availabilityStatus,
            availabilityUpdatedAt: $existing->availabilityUpdatedAt,
            deletedAt: $existing->deletedAt,
            deletedBy: $existing->deletedBy,
            mustChangePassword: false,
        );

        $this->byId[$id] = $updated;

        return $updated;
    }

    public function assignTemporaryPassword(string $id, string $passwordHash): User
    {
        $existing = $this->findById($id);

        if ($existing === null) {
            throw new UserNotFoundException;
        }

        $updated = new User(
            id: $existing->id,
            nameEn: $existing->nameEn,
            nameAr: $existing->nameAr,
            email: $existing->email,
            passwordHash: $passwordHash,
            role: $existing->role,
            isActive: $existing->isActive,
            phone: $existing->phone,
            branch: $existing->branch,
            availabilityStatus: $existing->availabilityStatus,
            availabilityUpdatedAt: $existing->availabilityUpdatedAt,
            deletedAt: $existing->deletedAt,
            deletedBy: $existing->deletedBy,
            mustChangePassword: true,
        );

        $this->byId[$id] = $updated;

        return $updated;
    }

    public function paginateUsers(
        ?UserRole $role,
        ?string $search,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $items = array_values(array_filter(
            $this->byId,
            function (User $user) use ($role, $search): bool {
                if ($user->isSoftDeleted()) {
                    return false;
                }

                if ($role !== null && $user->role !== $role) {
                    return false;
                }

                if ($search === null || $search === '') {
                    return true;
                }

                $haystack = strtolower(implode(' ', array_filter([
                    $user->nameEn,
                    $user->nameAr,
                    $user->email,
                    $user->phone,
                ])));

                return str_contains($haystack, strtolower($search));
            },
        ));

        usort($items, static fn (User $left, User $right): int => strcmp($left->nameEn, $right->nameEn));

        $offset = max(0, ($page - 1) * $perPage);

        return new PaginatedResult(
            items: array_values(array_slice($items, $offset, $perPage)),
            total: count($items),
            page: $page,
            perPage: $perPage,
        );
    }

    public function createWithRole(
        string $nameEn,
        ?string $nameAr,
        string $email,
        string $passwordHash,
        UserRole $role,
        ?string $phone = null,
        ?Branch $branch = null,
        bool $mustChangePassword = false,
    ): User {
        $user = new User(
            id: (string) Str::uuid(),
            nameEn: $nameEn,
            nameAr: $nameAr,
            email: $email,
            passwordHash: $passwordHash,
            role: $role,
            isActive: true,
            phone: $phone,
            branch: $branch,
            availabilityStatus: AvailabilityStatus::Unavailable,
            mustChangePassword: $mustChangePassword,
        );

        $this->byId[$user->id] = $user;
        $this->emailIndex[strtolower($email)] = $user->id;

        return $user;
    }

    public function paginateEmployees(
        ?bool $isActive,
        ?Branch $branch,
        ?string $search,
        bool $includeDeleted,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $items = array_values(array_filter(
            $this->byId,
            function (User $user) use ($isActive, $branch, $search, $includeDeleted): bool {
                if ($user->role !== UserRole::Employee) {
                    return false;
                }

                if (! $includeDeleted && $user->isSoftDeleted()) {
                    return false;
                }

                if ($isActive !== null && $user->isActive !== $isActive) {
                    return false;
                }

                if ($branch !== null && $user->branch !== $branch) {
                    return false;
                }

                if ($search !== null && $search !== '') {
                    $haystack = strtolower($user->nameEn.' '.$user->nameAr.' '.$user->email.' '.$user->phone);
                    if (! str_contains($haystack, strtolower($search))) {
                        return false;
                    }
                }

                return true;
            },
        ));

        $total = count($items);
        $offset = max(0, ($page - 1) * $perPage);
        $slice = array_slice($items, $offset, $perPage);

        return new PaginatedResult($slice, $total, $page, $perPage);
    }

    public function updateEmployee(
        string $id,
        string $nameEn,
        ?string $nameAr,
        ?string $phone,
        ?Branch $branch,
        bool $isActive,
        ?string $passwordHash,
    ): User {
        $existing = $this->findById($id);

        if ($existing === null || $existing->role !== UserRole::Employee) {
            throw new UserNotFoundException;
        }

        $updated = new User(
            id: $existing->id,
            nameEn: $nameEn,
            nameAr: $nameAr,
            email: $existing->email,
            passwordHash: $passwordHash ?? $existing->passwordHash,
            role: $existing->role,
            isActive: $isActive,
            phone: $phone,
            branch: $branch,
            availabilityStatus: $existing->availabilityStatus,
            availabilityUpdatedAt: $existing->availabilityUpdatedAt,
            deletedAt: $existing->deletedAt,
            deletedBy: $existing->deletedBy,
            mustChangePassword: $existing->mustChangePassword,
        );

        $this->byId[$id] = $updated;

        return $updated;
    }

    public function softDelete(string $id, string $deletedBy): User
    {
        $existing = $this->findById($id);

        if ($existing === null) {
            throw new UserNotFoundException;
        }

        $updated = new User(
            id: $existing->id,
            nameEn: $existing->nameEn,
            nameAr: $existing->nameAr,
            email: $existing->email,
            passwordHash: $existing->passwordHash,
            role: $existing->role,
            isActive: false,
            phone: $existing->phone,
            branch: $existing->branch,
            availabilityStatus: $existing->availabilityStatus,
            availabilityUpdatedAt: $existing->availabilityUpdatedAt,
            deletedAt: now()->toIso8601String(),
            deletedBy: $deletedBy,
            mustChangePassword: $existing->mustChangePassword,
        );

        $this->byId[$id] = $updated;

        return $updated;
    }

    public function restore(string $id): User
    {
        $existing = $this->findById($id, withTrashed: true);

        if ($existing === null) {
            throw new UserNotFoundException;
        }

        $updated = new User(
            id: $existing->id,
            nameEn: $existing->nameEn,
            nameAr: $existing->nameAr,
            email: $existing->email,
            passwordHash: $existing->passwordHash,
            role: $existing->role,
            isActive: true,
            phone: $existing->phone,
            branch: $existing->branch,
            availabilityStatus: $existing->availabilityStatus,
            availabilityUpdatedAt: $existing->availabilityUpdatedAt,
            deletedAt: null,
            deletedBy: null,
            mustChangePassword: $existing->mustChangePassword,
        );

        $this->byId[$id] = $updated;

        return $updated;
    }

    public function activeIdsForRole(UserRole $role): array
    {
        $ids = [];
        foreach ($this->byId as $user) {
            if ($user->role === $role && $user->isActive && ! $user->isSoftDeleted()) {
                $ids[] = $user->id;
            }
        }

        return $ids;
    }

    public function seed(User $user): void
    {
        $this->byId[$user->id] = $user;
        $this->emailIndex[strtolower($user->email)] = $user->id;
    }
}
