<?php

declare(strict_types=1);

namespace App\Domain\Repositories;

use App\Domain\Entities\Driver;
use App\Domain\Enums\DriverAttendanceFilter;
use App\Domain\Shared\PaginatedResult;

interface DriverRepositoryInterface
{
    public function findById(string $id, bool $withTrashed = false): ?Driver;

    /**
     * @return PaginatedResult<Driver>
     */
    public function paginate(
        ?bool $isActive,
        ?DriverAttendanceFilter $attendance,
        ?string $search,
        bool $includeDeleted,
        int $page,
        int $perPage,
    ): PaginatedResult;

    /**
     * Creates users + driver_profiles + favorite places atomically.
     *
     * @param  list<string>  $favoritePlaceIds
     */
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
    ): Driver;

    /**
     * @param  list<string>  $favoritePlaceIds
     */
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
    ): Driver;

    public function softDelete(string $id, string $deletedBy): Driver;

    public function restore(string $id): Driver;

    /**
     * Active, not soft-deleted drivers (for recommendations).
     *
     * @return list<Driver>
     */
    public function listActiveDrivers(): array;
}
