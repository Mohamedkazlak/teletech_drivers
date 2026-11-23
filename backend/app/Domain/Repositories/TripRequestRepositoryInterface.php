<?php

declare(strict_types=1);

namespace App\Domain\Repositories;

use App\Domain\Entities\GroupableTripRequest;
use App\Domain\Entities\PlaceSnapshot;
use App\Domain\Entities\TripRequest;
use App\Domain\Enums\Branch;
use App\Domain\Enums\TripRequestListBucket;
use App\Domain\Enums\TripRequestStage;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Shared\PaginatedResult;
use DateTimeImmutable;

interface TripRequestRepositoryInterface
{
    public function findById(string $id): ?TripRequest;

    /**
     * @return list<TripRequest>
     */
    public function listByTripId(string $tripId): array;

    public function findByIdForUpdate(string $id): ?TripRequest;

    /**
     * @param  list<string>  $ids
     * @return list<TripRequest>
     */
    public function findByIdsForUpdate(array $ids): array;

    /**
     * @return PaginatedResult<TripRequest>
     */
    public function paginateMine(
        string $employeeId,
        ?TripRequestStatus $status,
        ?DateTimeImmutable $dateFrom,
        ?DateTimeImmutable $dateTo,
        int $page,
        int $perPage,
        ?TripRequestListBucket $bucket = null,
        bool $awaitingConfirmation = false,
    ): PaginatedResult;

    /**
     * @return PaginatedResult<TripRequest>
     */
    public function paginateAdmin(
        ?TripRequestStatus $status,
        ?bool $hasTrip,
        ?DateTimeImmutable $dateFrom,
        ?DateTimeImmutable $dateTo,
        ?string $employeeId,
        ?string $search,
        int $page,
        int $perPage,
        ?Branch $branch = null,
        ?TripRequestStage $stage = null,
        ?string $period = null,
        ?string $periodDate = null,
    ): PaginatedResult;

    /**
     * @return list<GroupableTripRequest>
     */
    public function listGroupable(TripRequestStatus $status, bool $tripIdMustBeNull): array;

    public function create(
        string $employeeId,
        UserRole $requesterRole,
        PlaceSnapshot $pickup,
        PlaceSnapshot $destination,
        DateTimeImmutable $requestedAt,
        string $notes,
        TripRequestStatus $status,
        bool $autoApproved,
        ?string $handledBy,
        ?DateTimeImmutable $handledAt,
        ?string $linkedTripId = null,
    ): TripRequest;

    /**
     * Creates request + unassigned trip in one transaction.
     */
    public function createWithUnassignedTrip(
        string $employeeId,
        UserRole $requesterRole,
        PlaceSnapshot $pickup,
        PlaceSnapshot $destination,
        DateTimeImmutable $requestedAt,
        string $notes,
        TripRequestStatus $status,
        bool $autoApproved,
        string $handledBy,
        DateTimeImmutable $handledAt,
        string $createdBy,
    ): TripRequest;

    public function cancel(string $id): TripRequest;

    public function approve(string $id, string $handledBy, DateTimeImmutable $handledAt): TripRequest;

    /**
     * First requester to confirm a pending completed trip wins.
     * The trip row is locked so a concurrent confirm observes the new status.
     */
    public function confirmTrip(
        string $requestId,
        string $actorId,
        bool $driverShowedUp,
        ?string $note,
    ): TripRequest;

    public function reject(
        string $id,
        string $handledBy,
        DateTimeImmutable $handledAt,
        ?string $rejectionReason,
    ): TripRequest;

    /**
     * Approves all ids atomically with one server-generated suggested_group_id.
     *
     * @param  list<string>  $ids
     * @return list<TripRequest>
     */
    public function approveAsGroup(
        array $ids,
        string $handledBy,
        DateTimeImmutable $handledAt,
    ): array;
}
