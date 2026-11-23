<?php

declare(strict_types=1);

namespace App\Domain\Repositories;

use App\Domain\Entities\CountableTrip;
use App\Domain\Entities\TrackingPoint;
use App\Domain\Entities\Trip;
use App\Domain\Enums\Branch;
use App\Domain\Enums\CreatedTripListBucket;
use App\Domain\Enums\TripCreationMode;
use App\Domain\Enums\TripLifecycle;
use App\Domain\Enums\TripStage;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Shared\PaginatedResult;
use DateTimeImmutable;

interface TripRepositoryInterface
{
    public function findById(string $id): ?Trip;

    public function findByIdForUpdate(string $id): ?Trip;

    /**
     * @return PaginatedResult<Trip>
     */
    public function paginate(
        ?TripStatus $status,
        ?string $driverId,
        ?DateTimeImmutable $dateFrom,
        ?DateTimeImmutable $dateTo,
        int $page,
        int $perPage,
        ?TripStage $stage = null,
        ?Branch $branch = null,
        ?bool $driverShowedUp = null,
        ?string $period = null,
        ?string $periodDate = null,
        ?string $finishedPeriod = null,
        ?bool $unconfirmed = null,
        ?TripLifecycle $lifecycle = null,
        ?string $excludeRequesterId = null,
    ): PaginatedResult;

    /**
     * Same filters as {@see paginate}, limited to the trips this role calls "mine".
     * Bucket uses {@see CreatedTripListBucket}, the same trip statuses as the mine request buckets.
     *
     * @return PaginatedResult<Trip>
     */
    public function paginateForActor(
        string $actorId,
        UserRole $role,
        ?TripStatus $status,
        ?string $driverId,
        ?DateTimeImmutable $dateFrom,
        ?DateTimeImmutable $dateTo,
        int $page,
        int $perPage,
        ?TripStage $stage = null,
        ?Branch $branch = null,
        ?bool $driverShowedUp = null,
        ?string $period = null,
        ?string $periodDate = null,
        ?CreatedTripListBucket $bucket = null,
        ?string $finishedPeriod = null,
        ?bool $unconfirmed = null,
    ): PaginatedResult;

    /**
     * Non-cancelled trips whose scheduled_at falls in the Saturday fleet week
     * that contains now. Same week as driver recommendations.
     * Missing ids are zero. One grouped query, or none when $driverIds is empty.
     *
     * @param  list<string>  $driverIds
     * @return array<string, int>
     */
    public function countNonCancelledThisWeek(array $driverIds): array;

    /**
     * Ordered driven-route samples for a trip.
     * Location history is not stored, so this is empty.
     *
     * @return list<TrackingPoint>
     */
    public function trackingPoints(string $tripId): array;

    /**
     * @param  list<TripStatus>|null  $statuses
     * @return PaginatedResult<Trip>
     */
    public function paginateMine(
        string $driverId,
        ?TripStatus $status,
        int $page,
        int $perPage,
        ?array $statuses = null,
        ?string $period = null,
        ?string $periodDate = null,
    ): PaginatedResult;

    /**
     * @return PaginatedResult<Trip>
     */
    public function paginateCreatedBy(
        string $createdBy,
        ?CreatedTripListBucket $bucket,
        int $page,
        int $perPage,
    ): PaginatedResult;

    /**
     * @param  list<string>  $requestIds
     * @return list<Trip>
     */
    public function createFromRequests(
        array $requestIds,
        TripCreationMode $mode,
        ?DateTimeImmutable $scheduledAt,
        string $createdBy,
    ): array;

    public function assignDriver(string $tripId, string $driverId): Trip;

    public function cancel(string $tripId): Trip;

    public function isAssignableDriver(string $driverId): bool;

    public function startTrip(string $tripId, float $startLat, float $startLng): Trip;

    public function arriveAtDestination(
        string $tripId,
        int $goingDistanceM,
        string $goingRoute,
    ): Trip;

    public function startReturn(string $tripId): Trip;

    public function endTrip(
        string $tripId,
        int $returnDistanceM,
        string $returnRoute,
    ): Trip;

    /**
     * Pending confirmations requested at or before the cutoff become unconfirmed.
     * Already confirmed or unconfirmed rows are left unchanged.
     *
     * @return list<string> ids of trips that were marked unconfirmed
     */
    public function markPendingConfirmationsUnconfirmed(DateTimeImmutable $requestedAtOrBefore): array;

    /**
     * Linked request pickup/destination place ids for recommendation matching.
     *
     * @return list<string>
     */
    public function linkedPlaceIds(string $tripId): array;

    /**
     * All trips (for recommendation ranking). Prefer narrow filters in infra.
     *
     * @return list<Trip>
     */
    public function listAllForRecommendations(): array;

    /**
     * @param  list<TripStatus>  $statuses
     * @return list<Trip>
     */
    public function listByDriverAndStatuses(string $driverId, array $statuses): array;

    /**
     * In-progress trips with optional driver filter, for live map.
     *
     * @return list<Trip>
     */
    public function listInProgress(?string $driverId = null): array;

    /**
     * Completed trips that count toward driver stats.
     * status=completed, finished_at set, driver_showed_up IS NOT FALSE.
     * period all (or null) does not restrict finished_at.
     *
     * @return list<CountableTrip>
     */
    public function listCountableTrips(string $driverId, ?string $period, ?string $date): array;

    /**
     * That driver's completed trips, newest finished_at first.
     * period filters finished_at. Omitted or all means every completed trip.
     *
     * @return PaginatedResult<Trip>
     */
    public function paginateCompletedByDriver(
        string $driverId,
        ?string $period,
        ?string $date,
        int $page,
        int $perPage,
    ): PaginatedResult;
}
