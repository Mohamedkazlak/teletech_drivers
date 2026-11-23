<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Entities\Trip;
use App\Domain\Enums\TripStatus;
use DateTimeImmutable;

/**
 * Warns when a driver already has another trip within a time window
 * (mirrors Flutter DriverScheduleConflict).
 */
final class DriverScheduleConflict
{
    public function __construct(
        private readonly int $windowHours,
    ) {}

    public static function fromConfig(): self
    {
        return new self((int) config('teletech.schedule_conflict_window_hours', 2));
    }

    /**
     * @param  list<Trip>  $trips
     */
    public function hasConflict(
        array $trips,
        string $driverId,
        DateTimeImmutable $scheduledAt,
        ?string $excludingTripId = null,
    ): bool {
        $windowSeconds = $this->windowHours * 3600;

        foreach ($trips as $trip) {
            if ($trip->driverId !== $driverId) {
                continue;
            }
            if ($excludingTripId !== null && $trip->id === $excludingTripId) {
                continue;
            }
            if ($trip->status === TripStatus::Cancelled || $trip->status === TripStatus::Completed) {
                continue;
            }

            $diff = abs($trip->scheduledAt->getTimestamp() - $scheduledAt->getTimestamp());
            if ($diff <= $windowSeconds) {
                return true;
            }
        }

        return false;
    }
}
