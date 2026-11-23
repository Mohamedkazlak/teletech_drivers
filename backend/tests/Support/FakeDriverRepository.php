<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Domain\Entities\Driver;
use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\DriverAttendanceFilter;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\InvalidFavoritePlacesException;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Repositories\DriverRepositoryInterface;
use App\Domain\Repositories\PlaceRepositoryInterface;
use App\Domain\Shared\PaginatedResult;
use Illuminate\Support\Str;

final class FakeDriverRepository implements DriverRepositoryInterface
{
    /** @var array<string, Driver> */
    private array $byId = [];

    public bool $failProfileCreation = false;

    public function __construct(
        private readonly PlaceRepositoryInterface $places = new FakePlaceRepository,
    ) {}

    public function findById(string $id, bool $withTrashed = false): ?Driver
    {
        $driver = $this->byId[$id] ?? null;

        if ($driver === null) {
            return null;
        }

        if (! $withTrashed && $driver->user->isSoftDeleted()) {
            return null;
        }

        return $driver;
    }

    public function paginate(
        ?bool $isActive,
        ?DriverAttendanceFilter $attendance,
        ?string $search,
        bool $includeDeleted,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $items = array_values(array_filter(
            $this->byId,
            function (Driver $driver) use ($isActive, $attendance, $search, $includeDeleted): bool {
                $user = $driver->user;

                if (! $includeDeleted && $user->isSoftDeleted()) {
                    return false;
                }

                if ($isActive !== null && $user->isActive !== $isActive) {
                    return false;
                }

                if ($attendance === DriverAttendanceFilter::CheckedIn
                    && $user->availabilityStatus !== AvailabilityStatus::Available) {
                    return false;
                }
                if ($attendance === DriverAttendanceFilter::NotCheckedIn
                    && $user->availabilityStatus === AvailabilityStatus::Available) {
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

        return new PaginatedResult(
            array_slice($items, $offset, $perPage),
            $total,
            $page,
            $perPage,
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
    ): Driver {
        if (! $this->places->allExistAndActive($favoritePlaceIds)) {
            throw new InvalidFavoritePlacesException;
        }

        $user = new User(
            id: (string) Str::uuid(),
            nameEn: $nameEn,
            nameAr: $nameAr,
            email: $email,
            passwordHash: $passwordHash,
            role: UserRole::Driver,
            isActive: true,
            phone: $phone,
            branch: null,
            availabilityStatus: AvailabilityStatus::Unavailable,
            mustChangePassword: true,
        );

        if ($this->failProfileCreation) {
            throw new \RuntimeException('Simulated driver profile failure.');
        }

        $driver = new Driver(
            user: $user,
            nationalId: $nationalId,
            carLicense: $carLicense,
            personalLicense: $personalLicense,
            favoritePlaceIds: array_values($favoritePlaceIds),
        );

        $this->byId[$user->id] = $driver;

        return $driver;
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
    ): Driver {
        $existing = $this->findById($id);

        if ($existing === null) {
            throw new UserNotFoundException;
        }

        if (! $this->places->allExistAndActive($favoritePlaceIds)) {
            throw new InvalidFavoritePlacesException;
        }

        $user = $existing->user;
        $updatedUser = new User(
            id: $user->id,
            nameEn: $nameEn,
            nameAr: $nameAr,
            email: $user->email,
            passwordHash: $passwordHash ?? $user->passwordHash,
            role: $user->role,
            isActive: $isActive,
            phone: $phone,
            branch: $user->branch,
            availabilityStatus: $user->availabilityStatus,
            availabilityUpdatedAt: $user->availabilityUpdatedAt,
            deletedAt: $user->deletedAt,
            deletedBy: $user->deletedBy,
            mustChangePassword: $user->mustChangePassword,
        );

        $driver = new Driver(
            user: $updatedUser,
            nationalId: $nationalId,
            carLicense: $carLicense,
            personalLicense: $personalLicense,
            favoritePlaceIds: array_values($favoritePlaceIds),
        );

        $this->byId[$id] = $driver;

        return $driver;
    }

    public function softDelete(string $id, string $deletedBy): Driver
    {
        $existing = $this->findById($id);

        if ($existing === null) {
            throw new UserNotFoundException;
        }

        $user = $existing->user;
        $updatedUser = new User(
            id: $user->id,
            nameEn: $user->nameEn,
            nameAr: $user->nameAr,
            email: $user->email,
            passwordHash: $user->passwordHash,
            role: $user->role,
            isActive: false,
            phone: $user->phone,
            branch: $user->branch,
            availabilityStatus: $user->availabilityStatus,
            availabilityUpdatedAt: $user->availabilityUpdatedAt,
            deletedAt: now()->toIso8601String(),
            deletedBy: $deletedBy,
            mustChangePassword: $user->mustChangePassword,
        );

        $driver = new Driver(
            user: $updatedUser,
            nationalId: $existing->nationalId,
            carLicense: $existing->carLicense,
            personalLicense: $existing->personalLicense,
            favoritePlaceIds: $existing->favoritePlaceIds,
        );

        $this->byId[$id] = $driver;

        return $driver;
    }

    public function restore(string $id): Driver
    {
        $existing = $this->findById($id, withTrashed: true);

        if ($existing === null) {
            throw new UserNotFoundException;
        }

        $user = $existing->user;
        $updatedUser = new User(
            id: $user->id,
            nameEn: $user->nameEn,
            nameAr: $user->nameAr,
            email: $user->email,
            passwordHash: $user->passwordHash,
            role: $user->role,
            isActive: true,
            phone: $user->phone,
            branch: $user->branch,
            availabilityStatus: $user->availabilityStatus,
            availabilityUpdatedAt: $user->availabilityUpdatedAt,
            deletedAt: null,
            deletedBy: null,
            mustChangePassword: $user->mustChangePassword,
        );

        $driver = new Driver(
            user: $updatedUser,
            nationalId: $existing->nationalId,
            carLicense: $existing->carLicense,
            personalLicense: $existing->personalLicense,
            favoritePlaceIds: $existing->favoritePlaceIds,
        );

        $this->byId[$id] = $driver;

        return $driver;
    }

    public function seed(Driver $driver): void
    {
        $this->byId[$driver->user->id] = $driver;
    }

    public function listActiveDrivers(): array
    {
        $drivers = [];
        foreach ($this->byId as $driver) {
            if ($driver->user->isActive && $driver->user->deletedAt === null) {
                $drivers[] = $driver;
            }
        }

        return $drivers;
    }
}
