<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Entities\User as UserEntity;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\UserRepositoryInterface;
use App\Domain\Shared\PaginatedResult;
use App\Infrastructure\Persistence\Eloquent\Mappers\UserMapper;
use App\Models\User as UserModel;

final class EloquentUserRepository implements UserRepositoryInterface
{
    public function findById(string $id, bool $withTrashed = false): ?UserEntity
    {
        $query = UserModel::query();

        if ($withTrashed) {
            $query->withTrashed();
        }

        $model = $query->find($id);

        return $model === null ? null : UserMapper::toDomain($model);
    }

    public function findByEmail(string $email): ?UserEntity
    {
        $model = UserModel::query()->where('email', $email)->first();

        return $model === null ? null : UserMapper::toDomain($model);
    }

    public function createEmployee(
        string $nameEn,
        ?string $nameAr,
        string $email,
        string $passwordHash,
        ?string $phone,
        ?Branch $branch,
        bool $mustChangePassword = false,
    ): UserEntity {
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

    public function updateProfile(string $id, array $changes): UserEntity
    {
        $model = UserModel::query()->find($id);

        if ($model === null) {
            throw new UserNotFoundException;
        }

        $allowed = array_intersect_key($changes, array_flip([
            'name_en',
            'name_ar',
            'phone',
            'branch',
            'email',
        ]));

        if ($allowed !== []) {
            $model->fill($allowed);
            $model->save();
        }

        return UserMapper::toDomain($model->fresh());
    }

    public function updatePassword(string $id, string $passwordHash): UserEntity
    {
        $model = UserModel::query()->find($id);

        if ($model === null) {
            throw new UserNotFoundException;
        }

        $model->forceFill([
            'password' => $passwordHash,
            'must_change_password' => false,
        ]);
        $model->save();

        return UserMapper::toDomain($model->fresh());
    }

    public function assignTemporaryPassword(string $id, string $passwordHash): UserEntity
    {
        $model = UserModel::query()->find($id);

        if ($model === null) {
            throw new UserNotFoundException;
        }

        $model->forceFill([
            'password' => $passwordHash,
            'must_change_password' => true,
        ]);
        $model->save();

        return UserMapper::toDomain($model->fresh());
    }

    public function paginateUsers(
        ?UserRole $role,
        ?string $search,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $query = UserModel::query()->orderBy('name_en');

        if ($role !== null) {
            $query->where('role', $role);
        }

        if ($search !== null && $search !== '') {
            $query->where(function ($builder) use ($search): void {
                $builder
                    ->where('name_en', 'like', '%'.$search.'%')
                    ->orWhere('name_ar', 'like', '%'.$search.'%')
                    ->orWhere('email', 'like', '%'.$search.'%')
                    ->orWhere('phone', 'like', '%'.$search.'%');
            });
        }

        $paginator = $query->paginate(perPage: $perPage, page: $page);

        /** @var list<UserEntity> $items */
        $items = collect($paginator->items())
            ->map(fn (UserModel $model): UserEntity => UserMapper::toDomain($model))
            ->values()
            ->all();

        return new PaginatedResult(
            items: $items,
            total: $paginator->total(),
            page: $paginator->currentPage(),
            perPage: $paginator->perPage(),
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
    ): UserEntity {
        $model = new UserModel;
        $model->forceFill([
            'name_en' => $nameEn,
            'name_ar' => $nameAr,
            'email' => $email,
            'password' => $passwordHash,
            'role' => $role,
            'is_active' => true,
            'phone' => $phone,
            'branch' => $branch,
            'must_change_password' => $mustChangePassword,
        ]);
        $model->save();

        return UserMapper::toDomain($model);
    }

    public function paginateEmployees(
        ?bool $isActive,
        ?Branch $branch,
        ?string $search,
        bool $includeDeleted,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $query = UserModel::query()
            ->where('role', UserRole::Employee)
            ->orderBy('name_en');

        if ($includeDeleted) {
            $query->withTrashed();
        }

        if ($isActive !== null) {
            $query->where('is_active', $isActive);
        }

        if ($branch !== null) {
            $query->where('branch', $branch);
        }

        if ($search !== null && $search !== '') {
            $query->where(function ($builder) use ($search): void {
                $builder
                    ->where('name_en', 'like', '%'.$search.'%')
                    ->orWhere('name_ar', 'like', '%'.$search.'%')
                    ->orWhere('email', 'like', '%'.$search.'%')
                    ->orWhere('phone', 'like', '%'.$search.'%');
            });
        }

        $paginator = $query->paginate(perPage: $perPage, page: $page);

        /** @var list<UserEntity> $items */
        $items = collect($paginator->items())
            ->map(fn (UserModel $model): UserEntity => UserMapper::toDomain($model))
            ->values()
            ->all();

        return new PaginatedResult(
            items: $items,
            total: $paginator->total(),
            page: $paginator->currentPage(),
            perPage: $paginator->perPage(),
        );
    }

    public function updateEmployee(
        string $id,
        string $nameEn,
        ?string $nameAr,
        ?string $phone,
        ?Branch $branch,
        bool $isActive,
        ?string $passwordHash,
    ): UserEntity {
        $model = UserModel::query()
            ->where('role', UserRole::Employee)
            ->find($id);

        if ($model === null) {
            throw new UserNotFoundException;
        }

        $attributes = [
            'name_en' => $nameEn,
            'name_ar' => $nameAr,
            'phone' => $phone,
            'branch' => $branch,
            'is_active' => $isActive,
        ];

        if ($passwordHash !== null) {
            $attributes['password'] = $passwordHash;
        }

        $model->fill($attributes);
        $model->save();

        return UserMapper::toDomain($model->fresh());
    }

    public function softDelete(string $id, string $deletedBy): UserEntity
    {
        $model = UserModel::query()->find($id);

        if ($model === null) {
            throw new UserNotFoundException;
        }

        $model->forceFill([
            'is_active' => false,
            'deleted_by' => $deletedBy,
        ]);
        $model->save();
        $model->delete();

        return UserMapper::toDomain($model);
    }

    public function restore(string $id): UserEntity
    {
        $model = UserModel::query()->withTrashed()->find($id);

        if ($model === null) {
            throw new UserNotFoundException;
        }

        $model->restore();
        $model->forceFill([
            'is_active' => true,
            'deleted_by' => null,
        ]);
        $model->save();

        return UserMapper::toDomain($model->fresh());
    }

    public function activeIdsForRole(UserRole $role): array
    {
        return UserModel::query()
            ->where('role', $role->value)
            ->where('is_active', true)
            ->orderBy('id')
            ->pluck('id')
            ->map(static fn (mixed $id): string => (string) $id)
            ->values()
            ->all();
    }
}
