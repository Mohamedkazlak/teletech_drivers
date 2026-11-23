<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Entities\CountableTrip;
use App\Domain\Entities\Trip as TripEntity;
use App\Domain\Enums\Branch;
use App\Domain\Enums\CreatedTripListBucket;
use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripCreationMode;
use App\Domain\Enums\TripLifecycle;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStage;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\StateConflictException;
use App\Domain\Exceptions\TripNotFoundException;
use App\Domain\Exceptions\TripRequestNotFoundException;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Services\Trip\TripLocationSummarizer;
use App\Domain\Services\TripStatusTransitions;
use App\Domain\Shared\PaginatedResult;
use App\Infrastructure\Persistence\Eloquent\Mappers\TripMapper;
use App\Models\Trip as TripModel;
use App\Models\TripRequest as TripRequestModel;
use App\Models\User;
use DateTimeImmutable;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

final class EloquentTripRepository implements TripRepositoryInterface
{
    public function __construct(
        private readonly TripStatusTransitions $transitions,
        private readonly TripLocationSummarizer $summarizer,
    ) {}

    public function findById(string $id): ?TripEntity
    {
        $model = $this->tripQuery()->find($id);

        return $model === null ? null : TripMapper::toDomain($model);
    }

    public function findByIdForUpdate(string $id): ?TripEntity
    {
        return DB::transaction(function () use ($id): ?TripEntity {
            $model = TripModel::query()->whereKey($id)->lockForUpdate()->first();

            return $model === null ? null : TripMapper::toDomain($model);
        });
    }

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
    ): PaginatedResult {
        $query = $this->tripQuery()->orderByDesc('scheduled_at');
        $this->applyListFilters(
            $query,
            $status,
            $driverId,
            $dateFrom,
            $dateTo,
            $stage,
            $branch,
            $driverShowedUp,
            $period,
            $periodDate,
            $finishedPeriod,
            $unconfirmed,
            $lifecycle,
        );
        if ($excludeRequesterId !== null && $excludeRequesterId !== '') {
            $this->excludeRequestedBy($query, $excludeRequesterId);
        }

        return $this->toPaginated($query->paginate(perPage: $perPage, page: $page));
    }

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
    ): PaginatedResult {
        $query = $this->tripQuery()->orderByDesc('scheduled_at');
        $this->applyListFilters(
            $query,
            $status,
            $driverId,
            $dateFrom,
            $dateTo,
            $stage,
            $branch,
            $driverShowedUp,
            $period,
            $periodDate,
            $finishedPeriod,
            $unconfirmed,
        );
        if ($bucket !== null) {
            $query->whereIn('status', array_map(
                static fn (TripStatus $status): string => $status->value,
                $bucket->statuses(),
            ));
        }
        $this->limitToActor($query, $actorId, $role);

        return $this->toPaginated($query->paginate(perPage: $perPage, page: $page));
    }

    public function trackingPoints(string $tripId): array
    {
        // driver_locations keeps the latest point per driver (primary key
        // driver_id). It is not an ordered history for $tripId.
        return [];
    }

    public function paginateMine(
        string $driverId,
        ?TripStatus $status,
        int $page,
        int $perPage,
        ?array $statuses = null,
        ?string $period = null,
        ?string $periodDate = null,
    ): PaginatedResult {
        $query = $this->tripQuery()
            ->where('driver_id', $driverId)
            ->orderByDesc('scheduled_at');

        if ($statuses !== null && $statuses !== []) {
            $query->whereIn('status', array_map(
                static fn (TripStatus $item): string => $item->value,
                $statuses,
            ));
        } elseif ($status !== null) {
            $query->where('status', $status->value);
        }

        if ($period !== null && $period !== '') {
            $query->whereFleetPeriod('scheduled_at', $period, $periodDate);
        }

        return $this->toPaginated($query->paginate(perPage: $perPage, page: $page));
    }

    public function paginateCreatedBy(
        string $createdBy,
        ?CreatedTripListBucket $bucket,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $query = $this->tripQuery()
            ->where('created_by', $createdBy)
            ->orderByDesc('scheduled_at');

        if ($bucket !== null) {
            $query->whereIn('status', array_map(
                static fn (TripStatus $item): string => $item->value,
                $bucket->statuses(),
            ));
        }

        return $this->toPaginated($query->paginate(perPage: $perPage, page: $page));
    }

    public function createFromRequests(
        array $requestIds,
        TripCreationMode $mode,
        ?DateTimeImmutable $scheduledAt,
        string $createdBy,
    ): array {
        return DB::transaction(function () use ($requestIds, $mode, $scheduledAt, $createdBy): array {
            $requests = TripRequestModel::query()
                ->whereIn('id', $requestIds)
                ->orderBy('id')
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            if ($requests->count() !== count($requestIds)) {
                throw new TripRequestNotFoundException;
            }

            foreach ($requestIds as $requestId) {
                /** @var TripRequestModel $request */
                $request = $requests->get($requestId);
                if ($request->status !== TripRequestStatus::Approved || $request->trip_id !== null) {
                    throw new StateConflictException(
                        'Every request must be approved and not yet linked to a trip.',
                    );
                }
            }

            $createdTrips = [];

            if ($mode === TripCreationMode::OnePerRequest) {
                foreach ($requestIds as $requestId) {
                    /** @var TripRequestModel $request */
                    $request = $requests->get($requestId);
                    $trip = TripModel::query()->create([
                        'driver_id' => null,
                        'scheduled_at' => $request->requested_at,
                        'status' => TripStatus::Unassigned,
                        'created_by' => $createdBy,
                        'pickup_summary' => $request->pickup_name,
                        'destination_summary' => $request->destination_name,
                    ]);
                    $request->trip_id = $trip->id;
                    $request->save();
                    $createdTrips[] = TripMapper::toDomain(
                        $this->tripQuery()->findOrFail($trip->id),
                    );
                }

                return $createdTrips;
            }

            /** @var list<TripRequestModel> $ordered */
            $ordered = [];
            foreach ($requestIds as $requestId) {
                $ordered[] = $requests->get($requestId);
            }

            $trip = TripModel::query()->create([
                'driver_id' => null,
                'scheduled_at' => $scheduledAt,
                'status' => TripStatus::Unassigned,
                'created_by' => $createdBy,
                'pickup_summary' => $this->summarizer->summarize(
                    array_map(static fn (TripRequestModel $r): string => $r->pickup_name, $ordered),
                ),
                'destination_summary' => $this->summarizer->summarize(
                    array_map(static fn (TripRequestModel $r): string => $r->destination_name, $ordered),
                ),
            ]);

            foreach ($ordered as $request) {
                $request->trip_id = $trip->id;
                $request->save();
            }

            return [TripMapper::toDomain($this->tripQuery()->findOrFail($trip->id))];
        });
    }

    public function assignDriver(string $tripId, string $driverId): TripEntity
    {
        return DB::transaction(function () use ($tripId, $driverId): TripEntity {
            $model = TripModel::query()->whereKey($tripId)->lockForUpdate()->first();
            if ($model === null) {
                throw new TripNotFoundException;
            }

            if ($model->status === TripStatus::Unassigned) {
                $this->transitions->assertTransition($model->status, TripStatus::Assigned);
                $model->status = TripStatus::Assigned;
                $model->driver_id = $driverId;
                $model->assigned_at = now();
                $model->save();
            } elseif ($model->status === TripStatus::Assigned) {
                if (! $this->transitions->canReassign($model->status)) {
                    throw new StateConflictException('Trip cannot be reassigned in its current status.');
                }
                $model->driver_id = $driverId;
                if ($model->assigned_at === null) {
                    $model->assigned_at = now();
                }
                $model->save();
            } else {
                throw new StateConflictException(
                    'Driver can only be assigned when the trip is unassigned or assigned.',
                );
            }

            return TripMapper::toDomain($this->tripQuery()->findOrFail($tripId));
        });
    }

    public function cancel(string $tripId): TripEntity
    {
        return DB::transaction(function () use ($tripId): TripEntity {
            $model = TripModel::query()->whereKey($tripId)->lockForUpdate()->first();
            if ($model === null) {
                throw new TripNotFoundException;
            }

            $this->transitions->assertTransition($model->status, TripStatus::Cancelled);

            $model->status = TripStatus::Cancelled;
            $model->save();

            // Flutter: cancelTrip only flips trip status; linked requests keep trip_id.

            return TripMapper::toDomain($this->tripQuery()->findOrFail($tripId));
        });
    }

    public function isAssignableDriver(string $driverId): bool
    {
        return User::query()
            ->whereKey($driverId)
            ->where('role', UserRole::Driver)
            ->where('is_active', true)
            ->whereNull('deleted_at')
            ->exists();
    }

    public function startTrip(string $tripId, float $startLat, float $startLng): TripEntity
    {
        return DB::transaction(function () use ($tripId, $startLat, $startLng): TripEntity {
            $model = TripModel::query()->whereKey($tripId)->lockForUpdate()->first();
            if ($model === null) {
                throw new TripNotFoundException;
            }

            $this->transitions->assertTransition($model->status, TripStatus::Going);

            $now = now();
            $model->status = TripStatus::Going;
            $model->going_started_at = $now;
            $model->start_lat = $startLat;
            $model->start_lng = $startLng;
            $model->save();

            return TripMapper::toDomain($this->tripQuery()->findOrFail($tripId));
        });
    }

    public function arriveAtDestination(
        string $tripId,
        int $goingDistanceM,
        string $goingRoute,
    ): TripEntity {
        return DB::transaction(function () use ($tripId, $goingDistanceM, $goingRoute): TripEntity {
            $model = TripModel::query()->whereKey($tripId)->lockForUpdate()->first();
            if ($model === null) {
                throw new TripNotFoundException;
            }

            $this->transitions->assertTransition($model->status, TripStatus::AtDestination);

            $model->status = TripStatus::AtDestination;
            $model->going_ended_at = now();
            $model->going_distance_m = $goingDistanceM;
            $model->going_route = $goingRoute;
            $model->save();

            return TripMapper::toDomain($this->tripQuery()->findOrFail($tripId));
        });
    }

    public function startReturn(string $tripId): TripEntity
    {
        return DB::transaction(function () use ($tripId): TripEntity {
            $model = TripModel::query()->whereKey($tripId)->lockForUpdate()->first();
            if ($model === null) {
                throw new TripNotFoundException;
            }

            $this->transitions->assertTransition($model->status, TripStatus::Returning);

            $model->status = TripStatus::Returning;
            $model->return_started_at = now();
            $model->save();

            return TripMapper::toDomain($this->tripQuery()->findOrFail($tripId));
        });
    }

    public function endTrip(
        string $tripId,
        int $returnDistanceM,
        string $returnRoute,
    ): TripEntity {
        return DB::transaction(function () use ($tripId, $returnDistanceM, $returnRoute): TripEntity {
            $model = TripModel::query()->whereKey($tripId)->lockForUpdate()->first();
            if ($model === null) {
                throw new TripNotFoundException;
            }

            $this->transitions->assertTransition($model->status, TripStatus::Completed);

            $goingDistance = (int) ($model->going_distance_m ?? 0);
            $now = now();
            $model->status = TripStatus::Completed;
            $model->finished_at = $now;
            $model->return_distance_m = $returnDistanceM;
            $model->return_route = $returnRoute;
            $model->total_distance_m = $goingDistance + $returnDistanceM;
            $model->confirmation_status = TripConfirmationStatus::Pending;
            $model->confirmation_requested_at = $now;
            $model->save();

            return TripMapper::toDomain($this->tripQuery()->findOrFail($tripId));
        });
    }

    public function markPendingConfirmationsUnconfirmed(DateTimeImmutable $requestedAtOrBefore): array
    {
        $ids = TripModel::query()
            ->where('confirmation_status', TripConfirmationStatus::Pending->value)
            ->whereNotNull('confirmation_requested_at')
            ->where('confirmation_requested_at', '<=', $requestedAtOrBefore)
            ->pluck('id')
            ->map(static fn (mixed $id): string => (string) $id)
            ->all();

        if ($ids === []) {
            return [];
        }

        TripModel::query()->whereIn('id', $ids)->update([
            'confirmation_status' => TripConfirmationStatus::Unconfirmed->value,
            'updated_at' => now(),
        ]);

        return array_values($ids);
    }

    public function linkedPlaceIds(string $tripId): array
    {
        $requests = TripRequestModel::query()
            ->where('trip_id', $tripId)
            ->get(['pickup_place_id', 'destination_place_id']);

        $placeIds = [];
        foreach ($requests as $request) {
            if ($request->pickup_place_id !== null && $request->pickup_place_id !== '') {
                $placeIds[] = (string) $request->pickup_place_id;
            }
            if ($request->destination_place_id !== null && $request->destination_place_id !== '') {
                $placeIds[] = (string) $request->destination_place_id;
            }
        }

        return array_values(array_unique($placeIds));
    }

    public function listAllForRecommendations(): array
    {
        return $this->tripQuery()
            ->orderBy('scheduled_at')
            ->get()
            ->map(static fn (TripModel $model): TripEntity => TripMapper::toDomain($model))
            ->values()
            ->all();
    }

    public function listByDriverAndStatuses(string $driverId, array $statuses): array
    {
        $values = array_map(static fn (TripStatus $status): string => $status->value, $statuses);

        return $this->tripQuery()
            ->where('driver_id', $driverId)
            ->whereIn('status', $values)
            ->get()
            ->map(static fn (TripModel $model): TripEntity => TripMapper::toDomain($model))
            ->values()
            ->all();
    }

    public function listInProgress(?string $driverId = null): array
    {
        $query = $this->tripQuery()->whereIn('status', [
            TripStatus::Going->value,
            TripStatus::AtDestination->value,
            TripStatus::Returning->value,
        ]);

        if ($driverId !== null && $driverId !== '') {
            $query->where('driver_id', $driverId);
        }

        return $query
            ->orderBy('going_started_at')
            ->get()
            ->map(static fn (TripModel $model): TripEntity => TripMapper::toDomain($model))
            ->values()
            ->all();
    }

    public function listCountableTrips(string $driverId, ?string $period, ?string $date): array
    {
        $models = TripModel::query()
            ->where('driver_id', $driverId)
            ->where('status', TripStatus::Completed->value)
            ->whereNotNull('finished_at')
            ->where(function ($query): void {
                // Portable form of PostgreSQL "driver_showed_up IS NOT FALSE"
                // (true and null count; false does not). Works on SQLite too.
                $query->where('driver_showed_up', true)
                    ->orWhereNull('driver_showed_up');
            })
            ->whereFleetPeriod('finished_at', $period, $date)
            ->orderBy('finished_at')
            ->get(['going_started_at', 'finished_at', 'total_distance_m']);

        $trips = [];
        foreach ($models as $model) {
            if ($model->finished_at === null) {
                continue;
            }

            $trips[] = new CountableTrip(
                goingStartedAt: $model->going_started_at !== null
                    ? DateTimeImmutable::createFromMutable($model->going_started_at)
                    : null,
                finishedAt: DateTimeImmutable::createFromMutable($model->finished_at),
                totalDistanceM: $model->total_distance_m !== null ? (int) $model->total_distance_m : null,
            );
        }

        return $trips;
    }

    public function paginateCompletedByDriver(
        string $driverId,
        ?string $period,
        ?string $date,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $query = TripModel::query()
            ->where('driver_id', $driverId)
            ->where('status', TripStatus::Completed->value)
            ->whereFleetPeriod('finished_at', $period, $date)
            ->orderByRaw('CASE WHEN finished_at IS NULL THEN 1 ELSE 0 END')
            ->orderByDesc('finished_at')
            ->orderByDesc('id');

        return $this->toPaginated($query->paginate(perPage: $perPage, page: $page));
    }

    public function countNonCancelledThisWeek(array $driverIds): array
    {
        $counts = [];
        foreach ($driverIds as $driverId) {
            $counts[$driverId] = 0;
        }

        if ($counts === []) {
            return [];
        }

        $rows = TripModel::query()
            ->whereIn('driver_id', array_keys($counts))
            ->where('status', '!=', TripStatus::Cancelled->value)
            ->whereFleetPeriod('scheduled_at', 'week')
            ->select('driver_id')
            ->selectRaw('COUNT(*) as trips_this_week')
            ->groupBy('driver_id')
            ->get();

        foreach ($rows as $row) {
            $counts[(string) $row->getAttribute('driver_id')] = (int) $row->getAttribute('trips_this_week');
        }

        return $counts;
    }

    private function applyListFilters(
        mixed $query,
        ?TripStatus $status,
        ?string $driverId,
        ?DateTimeImmutable $dateFrom,
        ?DateTimeImmutable $dateTo,
        ?TripStage $stage,
        ?Branch $branch,
        ?bool $driverShowedUp,
        ?string $period = null,
        ?string $periodDate = null,
        ?string $finishedPeriod = null,
        ?bool $unconfirmed = null,
        ?TripLifecycle $lifecycle = null,
    ): void {
        if ($lifecycle !== null) {
            $query->whereIn('status', array_map(
                static fn (TripStatus $item): string => $item->value,
                $lifecycle->statuses(),
            ));
        }

        if ($status !== null) {
            $query->where('status', $status->value);
        }

        if ($stage !== null) {
            $query->whereIn('status', array_map(
                static fn (TripStatus $item): string => $item->value,
                $stage->statuses(),
            ));

            $confirmations = $stage->confirmationStatuses();
            if ($confirmations !== null) {
                $query->whereIn('confirmation_status', array_map(
                    static fn (TripConfirmationStatus $item): string => $item->value,
                    $confirmations,
                ));
            }
        }

        if ($driverShowedUp !== null) {
            $query->where('driver_showed_up', $driverShowedUp);
        }

        if ($unconfirmed !== null) {
            $query->whereUnconfirmed($unconfirmed);
        }

        if ($branch !== null) {
            $query->whereHas('tripRequests.employee', function ($employee) use ($branch): void {
                $employee->where('branch', $branch->value);
            });
        }

        if ($driverId !== null && $driverId !== '') {
            $query->where('driver_id', $driverId);
        }

        if ($dateFrom !== null) {
            $query->where('scheduled_at', '>=', $dateFrom);
        }

        if ($dateTo !== null) {
            $query->where('scheduled_at', '<=', $dateTo);
        }

        // An explicit date_from / date_to replaces the period window.
        if ($dateFrom === null && $dateTo === null && $period !== null && $period !== '' && $period !== 'custom') {
            $query->whereFleetPeriod('scheduled_at', $period, $periodDate);
        }

        // finished_period filters finished_at and stays combined with every other filter.
        if ($finishedPeriod !== null && $finishedPeriod !== '' && $finishedPeriod !== 'custom') {
            $query->whereFleetPeriod('finished_at', $finishedPeriod, $periodDate);
        }
    }

    private function limitToActor(mixed $query, string $actorId, UserRole $role): void
    {
        match ($role) {
            UserRole::Driver => $query->where('driver_id', $actorId),
            UserRole::DriversAdmin,
            UserRole::Admin,
            UserRole::CompanyAdmin,
            UserRole::Employee => $this->whereRequestedBy($query, $actorId),
        };
    }

    /**
     * The requester is trip_requests.employee_id, not trips.created_by.
     * created_by is the dispatcher who opened the trip, including trips built
     * from someone else's request.
     */
    private function whereRequestedBy(mixed $query, string $requesterId): void
    {
        $query->whereHas('tripRequests', static function ($requests) use ($requesterId): void {
            $requests->where('employee_id', $requesterId);
        });
    }

    private function excludeRequestedBy(mixed $query, string $requesterId): void
    {
        $query->whereDoesntHave('tripRequests', static function ($requests) use ($requesterId): void {
            $requests->where('employee_id', $requesterId);
        });
    }

    private function tripQuery(): mixed
    {
        return TripModel::query()->with([
            'tripRequests.employee',
            'driver.driverProfile',
            'driver.favoritePlaces',
            'confirmedBy',
        ]);
    }

    /**
     * @param  LengthAwarePaginator<int, TripModel>  $paginator
     * @return PaginatedResult<TripEntity>
     */
    private function toPaginated(mixed $paginator): PaginatedResult
    {
        /** @var list<TripEntity> $items */
        $items = collect($paginator->items())
            ->map(static fn (TripModel $model): TripEntity => TripMapper::toDomain($model))
            ->values()
            ->all();

        return new PaginatedResult(
            items: $items,
            total: $paginator->total(),
            page: $paginator->currentPage(),
            perPage: $paginator->perPage(),
        );
    }
}
