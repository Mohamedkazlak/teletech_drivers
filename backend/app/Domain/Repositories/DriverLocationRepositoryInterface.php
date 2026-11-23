<?php

declare(strict_types=1);

namespace App\Domain\Repositories;

use App\Domain\Entities\DriverLocation;
use App\Domain\Entities\LiveMapDriver;
use App\Domain\Enums\DriverAttendanceFilter;
use DateTimeImmutable;

interface DriverLocationRepositoryInterface
{
    public function findByDriverId(string $driverId): ?DriverLocation;

    public function upsert(
        string $driverId,
        ?string $tripId,
        float $lat,
        float $lng,
        float $heading,
        float $speed,
        float $accuracy,
        bool $isTracking,
    ): DriverLocation;

    public function stopTracking(string $driverId): DriverLocation;

    /**
     * Every active, non-deleted driver. Location fields are null when the
     * driver has no driver_locations row. Trip is null when not in progress.
     *
     * @return list<LiveMapDriver>
     */
    public function listLiveMap(?string $driverId = null, ?DriverAttendanceFilter $attendance = null): array;

    /**
     * Last known position from an approved availability request.
     * Writes only when $observedAt is newer than the stored updated_at.
     * Leaves is_tracking (and heading, speed, accuracy, trip_id) unchanged.
     */
    public function upsertLastKnownIfNewer(
        string $driverId,
        float $lat,
        float $lng,
        DateTimeImmutable $observedAt,
    ): void;
}
