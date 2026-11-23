<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Entities\Driver as DriverEntity;
use App\Domain\Enums\DriverAttendanceFilter;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\InvalidFavoritePlacesException;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\DriverRepositoryInterface;
use App\Domain\Repositories\PlaceRepositoryInterface;
use App\Domain\Shared\PaginatedResult;
use App\Infrastructure\Persistence\Eloquent\Mappers\DriverMapper;
use App\Models\DriverProfile;
use App\Models\User as UserModel;
use Illuminate\Support\Facades\DB;

final class EloquentDriverRepository implements DriverRepositoryInterface
{
    public function __construct(
        private readonly PlaceRepositoryInterface $places,
    ) {}

    public function findById(string $id, bool $withTrashed = false): ?DriverEntity
    {
        $query = UserModel::query()->where('role', UserRole::Driver);

        if ($withTrashed) {
            $query->withTrashed();
        }

        $model = $query
            ->with(['driverProfile', 'favoritePlaces', 'todayAttendance', 'activeTrip'])
            ->find($id);

        return $model === null ? null : DriverMapper::toDomain($model);
    }

    public function paginate(
        ?bool $isActive,
        ?DriverAttendanceFilter $attendance,
        ?string $search,
        bool $includeDeleted,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $query = UserModel::query()
            ->where('role', UserRole::Driver)
            ->with(['driverProfile', 'favoritePlaces', 'todayAttendance', 'activeTrip'])
            ->orderBy('name_en');

        if ($includeDeleted) {
            $query->withTrashed();
        }

        if ($isActive !== null) {
            $query->where('is_active', $isActive);
        }

        if ($attendance === DriverAttendanceFilter::CheckedIn) {
            $query->checkedInToday();
        } elseif ($attendance === DriverAttendanceFilter::NotCheckedIn) {
            $query->notCheckedInToday();
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

        /** @var list<DriverEntity> $items */
        $items = collect($paginator->items())
            ->map(fn (UserModel $model): DriverEntity => DriverMapper::toDomain($model))
            ->values()
            ->all();

        return new PaginatedResult(
            items: $items,
            total: $paginator->total(),
            page: $paginator->currentPage(),
            perPage: $paginator->perPage(),
        );
    }

    public function create(
        string $nameEn,
        string $nameAr,
        string $email,
        string $passwordHash,
        ?string $phone,
        string $nationalId,
        string $carLicense,
        string $personalLicense,
        array $favoritePlaceIds,
    ): DriverEntity {
        if (! $this->places->allExistAndActive($favoritePlaceIds)) {
            throw new InvalidFavoritePlacesException;
        }

        return DB::transaction(function () use (
            $nameEn,
            $nameAr,
            $email,
            $passwordHash,
            $phone,
            $nationalId,
            $carLicense,
            $personalLicense,
            $favoritePlaceIds,
        ): DriverEntity {
            $user = new UserModel;
            $user->forceFill([
                'name_en' => $nameEn,
                'name_ar' => $nameAr,
                'email' => $email,
                'password' => $passwordHash,
                'role' => UserRole::Driver,
                'is_active' => true,
                'phone' => $phone,
                'branch' => null,
                'must_change_password' => true,
            ]);
            $user->save();

            DriverProfile::query()->create([
                'user_id' => $user->id,
                'national_id' => $nationalId,
                'car_license' => $carLicense,
                'personal_license' => $personalLicense,
            ]);

            $user->favoritePlaces()->sync($favoritePlaceIds);

            $user->load(['driverProfile', 'favoritePlaces', 'todayAttendance', 'activeTrip']);

            return DriverMapper::toDomain($user);
        });
    }

    public function update(
        string $id,
        string $nameEn,
        ?string $nameAr,
        ?string $phone,
        string $nationalId,
        string $carLicense,
        string $personalLicense,
        array $favoritePlaceIds,
        bool $isActive,
        ?string $passwordHash,
    ): DriverEntity {
        if (! $this->places->allExistAndActive($favoritePlaceIds)) {
            throw new InvalidFavoritePlacesException;
        }

        return DB::transaction(function () use (
            $id,
            $nameEn,
            $nameAr,
            $phone,
            $nationalId,
            $carLicense,
            $personalLicense,
            $favoritePlaceIds,
            $isActive,
            $passwordHash,
        ): DriverEntity {
            $user = UserModel::query()
                ->where('role', UserRole::Driver)
                ->find($id);

            if ($user === null) {
                throw new UserNotFoundException;
            }

            $attributes = [
                'name_en' => $nameEn,
                'name_ar' => $nameAr,
                'phone' => $phone,
                'is_active' => $isActive,
            ];

            if ($passwordHash !== null) {
                $attributes['password'] = $passwordHash;
            }

            $user->fill($attributes);
            $user->save();

            DriverProfile::query()->updateOrCreate(
                ['user_id' => $user->id],
                [
                    'national_id' => $nationalId,
                    'car_license' => $carLicense,
                    'personal_license' => $personalLicense,
                ],
            );

            $user->favoritePlaces()->sync($favoritePlaceIds);
            $user->load(['driverProfile', 'favoritePlaces', 'todayAttendance', 'activeTrip']);

            return DriverMapper::toDomain($user);
        });
    }

    public function softDelete(string $id, string $deletedBy): DriverEntity
    {
        $user = UserModel::query()
            ->where('role', UserRole::Driver)
            ->find($id);

        if ($user === null) {
            throw new UserNotFoundException;
        }

        $user->forceFill([
            'is_active' => false,
            'deleted_by' => $deletedBy,
        ]);
        $user->save();
        $user->delete();

        $user->load(['driverProfile', 'favoritePlaces', 'todayAttendance', 'activeTrip']);

        return DriverMapper::toDomain($user);
    }

    public function restore(string $id): DriverEntity
    {
        $user = UserModel::query()
            ->where('role', UserRole::Driver)
            ->withTrashed()
            ->find($id);

        if ($user === null) {
            throw new UserNotFoundException;
        }

        $user->restore();
        $user->forceFill([
            'is_active' => true,
            'deleted_by' => null,
        ]);
        $user->save();
        $user->load(['driverProfile', 'favoritePlaces', 'todayAttendance', 'activeTrip']);

        return DriverMapper::toDomain($user);
    }

    public function listActiveDrivers(): array
    {
        $users = UserModel::query()
            ->where('role', UserRole::Driver)
            ->where('is_active', true)
            ->whereNull('deleted_at')
            ->with(['driverProfile', 'favoritePlaces', 'todayAttendance', 'activeTrip'])
            ->orderBy('name_en')
            ->get();

        return $users
            ->map(static fn (UserModel $user): DriverEntity => DriverMapper::toDomain($user))
            ->values()
            ->all();
    }
}
