<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Entities\GroupableTripRequest;
use App\Domain\Entities\PlaceSnapshot;
use App\Domain\Entities\TripRequest as TripRequestEntity;
use App\Domain\Enums\Branch;
use App\Domain\Enums\CreatedTripListBucket;
use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripRequestListBucket;
use App\Domain\Enums\TripRequestStage;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\StateConflictException;
use App\Domain\Exceptions\TripRequestNotFoundException;
use App\Domain\Repositories\TripRequestRepositoryInterface;
use App\Domain\Shared\PaginatedResult;
use App\Infrastructure\Persistence\Eloquent\Mappers\TripRequestMapper;
use App\Models\Trip as TripModel;
use App\Models\TripRequest as TripRequestModel;
use DateTimeImmutable;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class EloquentTripRequestRepository implements TripRequestRepositoryInterface
{
    public function findById(string $id): ?TripRequestEntity
    {
        $model = $this->requestQuery()->find($id);

        return $model === null ? null : TripRequestMapper::toDomain($model);
    }

    public function listByTripId(string $tripId): array
    {
        return $this->requestQuery()
            ->where('trip_id', $tripId)
            ->orderBy('id')
            ->get()
            ->map(static fn (TripRequestModel $model): TripRequestEntity => TripRequestMapper::toDomain($model))
            ->values()
            ->all();
    }

    public function findByIdForUpdate(string $id): ?TripRequestEntity
    {
        return DB::transaction(function () use ($id): ?TripRequestEntity {
            $model = TripRequestModel::query()->whereKey($id)->lockForUpdate()->first();

            return $model === null ? null : TripRequestMapper::toDomain($model);
        });
    }

    public function findByIdsForUpdate(array $ids): array
    {
        return DB::transaction(function () use ($ids): array {
            $models = TripRequestModel::query()
                ->whereIn('id', $ids)
                ->orderBy('id')
                ->lockForUpdate()
                ->get();

            return $models
                ->map(static fn (TripRequestModel $model): TripRequestEntity => TripRequestMapper::toDomain($model))
                ->values()
                ->all();
        });
    }

    public function paginateMine(
        string $employeeId,
        ?TripRequestStatus $status,
        ?DateTimeImmutable $dateFrom,
        ?DateTimeImmutable $dateTo,
        int $page,
        int $perPage,
        ?TripRequestListBucket $bucket = null,
        bool $awaitingConfirmation = false,
    ): PaginatedResult {
        $query = $this->requestQuery()
            ->where('employee_id', $employeeId)
            ->orderByDesc('created_at');

        $this->applyCommonFilters($query, $status, $dateFrom, $dateTo);

        if ($bucket !== null) {
            $this->applyMineBucket($query, $bucket);
        }

        if ($awaitingConfirmation) {
            $query->whereHas('trip', function ($trip): void {
                $trip->where('status', TripStatus::Completed->value)
                    ->where('confirmation_status', TripConfirmationStatus::Pending->value);
            });
        }

        return $this->toPaginated($query->paginate(perPage: $perPage, page: $page));
    }

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
    ): PaginatedResult {
        $query = $this->requestQuery()->orderByDesc('created_at');

        $this->applyCommonFilters($query, $status, $dateFrom, $dateTo);

        if ($hasTrip === true) {
            $query->whereNotNull('trip_id');
        } elseif ($hasTrip === false) {
            $query->whereNull('trip_id');
        }

        if ($branch !== null) {
            $query->whereHas('employee', function ($employee) use ($branch): void {
                $employee->where('branch', $branch->value);
            });
        }

        if ($stage === TripRequestStage::NeedsDriver) {
            $query->whereNull('trip_id');
        } elseif ($stage === TripRequestStage::Assigned) {
            $query->whereNotNull('trip_id');
        }

        if ($employeeId !== null && $employeeId !== '') {
            $query->where('employee_id', $employeeId);
        }

        if ($period !== null && $period !== '') {
            $query->whereFleetPeriod('requested_at', $period, $periodDate);
        }

        if ($search !== null && $search !== '') {
            $query->where(function ($builder) use ($search): void {
                $builder
                    ->where('pickup_name', 'like', '%'.$search.'%')
                    ->orWhere('destination_name', 'like', '%'.$search.'%')
                    ->orWhere('notes', 'like', '%'.$search.'%')
                    ->orWhereHas('employee', function ($employeeQuery) use ($search): void {
                        $employeeQuery
                            ->where('name_en', 'like', '%'.$search.'%')
                            ->orWhere('name_ar', 'like', '%'.$search.'%')
                            ->orWhere('email', 'like', '%'.$search.'%');
                    });
            });
        }

        return $this->toPaginated($query->paginate(perPage: $perPage, page: $page));
    }

    public function listGroupable(TripRequestStatus $status, bool $tripIdMustBeNull): array
    {
        $query = TripRequestModel::query()->where('status', $status->value);

        if ($tripIdMustBeNull) {
            $query->whereNull('trip_id');
        }

        return $query->with('employee')->get()
            ->map(static fn (TripRequestModel $model): GroupableTripRequest => TripRequestMapper::toGroupable($model))
            ->values()
            ->all();
    }

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
    ): TripRequestEntity {
        $model = TripRequestModel::query()->create([
            ...$this->attributesFromSnapshots($pickup, $destination),
            'employee_id' => $employeeId,
            'requester_role' => $requesterRole,
            'requested_at' => $requestedAt,
            'notes' => $notes,
            'status' => $status,
            'trip_id' => $linkedTripId,
            'handled_by' => $handledBy,
            'handled_at' => $handledAt,
            'approved_at' => $autoApproved ? $handledAt : null,
            'auto_approved' => $autoApproved,
        ]);

        return TripRequestMapper::toDomain($model->load(['employee', 'trip.driver']));
    }

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
    ): TripRequestEntity {
        return DB::transaction(function () use (
            $employeeId,
            $requesterRole,
            $pickup,
            $destination,
            $requestedAt,
            $notes,
            $status,
            $autoApproved,
            $handledBy,
            $handledAt,
            $createdBy,
        ): TripRequestEntity {
            $trip = TripModel::query()->create([
                'driver_id' => null,
                'scheduled_at' => $requestedAt,
                'status' => TripStatus::Unassigned,
                'created_by' => $createdBy,
                'pickup_summary' => $pickup->name,
                'destination_summary' => $destination->name,
            ]);

            $request = TripRequestModel::query()->create([
                ...$this->attributesFromSnapshots($pickup, $destination),
                'employee_id' => $employeeId,
                'requester_role' => $requesterRole,
                'requested_at' => $requestedAt,
                'notes' => $notes,
                'status' => $status,
                'trip_id' => $trip->id,
                'handled_by' => $handledBy,
                'handled_at' => $handledAt,
                'approved_at' => $autoApproved ? $handledAt : null,
                'auto_approved' => $autoApproved,
            ]);

            return TripRequestMapper::toDomain($request->load(['employee', 'trip.driver']));
        });
    }

    public function cancel(string $id): TripRequestEntity
    {
        return DB::transaction(function () use ($id): TripRequestEntity {
            $model = TripRequestModel::query()->whereKey($id)->lockForUpdate()->first();
            if ($model === null) {
                throw new TripRequestNotFoundException;
            }

            $entity = TripRequestMapper::toDomain($model);
            if (! $entity->canCancel()) {
                throw new StateConflictException(
                    'Only pending requests, or approved requests without a trip, can be cancelled.',
                );
            }

            $model->status = TripRequestStatus::Cancelled;
            $model->save();

            return TripRequestMapper::toDomain($model->fresh()->load(['employee', 'trip.driver']));
        });
    }

    public function approve(string $id, string $handledBy, DateTimeImmutable $handledAt): TripRequestEntity
    {
        return DB::transaction(function () use ($id, $handledBy, $handledAt): TripRequestEntity {
            $model = TripRequestModel::query()->whereKey($id)->lockForUpdate()->first();
            if ($model === null) {
                throw new TripRequestNotFoundException;
            }

            if ($model->status !== TripRequestStatus::Pending) {
                throw new StateConflictException('Only pending trip requests can be approved.');
            }

            $model->status = TripRequestStatus::Approved;
            $model->handled_by = $handledBy;
            $model->handled_at = $handledAt;
            $model->approved_at = $handledAt;
            $model->save();

            return TripRequestMapper::toDomain($model->fresh()->load(['employee', 'trip.driver']));
        });
    }

    public function confirmTrip(
        string $requestId,
        string $actorId,
        bool $driverShowedUp,
        ?string $note,
    ): TripRequestEntity {
        return DB::transaction(function () use ($requestId, $actorId, $driverShowedUp, $note): TripRequestEntity {
            $request = TripRequestModel::query()->whereKey($requestId)->lockForUpdate()->first();
            if ($request === null) {
                throw new TripRequestNotFoundException;
            }

            if ($request->trip_id === null) {
                throw new StateConflictException(
                    'Trip request is not linked to a completed trip awaiting confirmation.',
                );
            }

            $trip = TripModel::query()->whereKey($request->trip_id)->lockForUpdate()->first();
            if ($trip === null) {
                throw new StateConflictException(
                    'Trip request is not linked to a completed trip awaiting confirmation.',
                );
            }

            if ($trip->confirmation_status === TripConfirmationStatus::Confirmed) {
                throw new StateConflictException('This trip has already been confirmed.');
            }

            if ($trip->confirmation_status === TripConfirmationStatus::Unconfirmed) {
                throw new StateConflictException('This trip is already unconfirmed.');
            }

            if ($trip->status !== TripStatus::Completed
                || $trip->confirmation_status !== TripConfirmationStatus::Pending) {
                throw new StateConflictException(
                    'Trip request is not linked to a completed trip awaiting confirmation.',
                );
            }

            $trip->confirmation_status = TripConfirmationStatus::Confirmed;
            $trip->confirmed_at = now();
            $trip->confirmed_by = $actorId;
            $trip->driver_showed_up = $driverShowedUp;
            $trip->confirmation_note = $note;
            $trip->save();

            return TripRequestMapper::toDomain($this->requestQuery()->findOrFail($requestId));
        });
    }

    public function reject(
        string $id,
        string $handledBy,
        DateTimeImmutable $handledAt,
        ?string $rejectionReason,
    ): TripRequestEntity {
        return DB::transaction(function () use ($id, $handledBy, $handledAt, $rejectionReason): TripRequestEntity {
            $model = TripRequestModel::query()->whereKey($id)->lockForUpdate()->first();
            if ($model === null) {
                throw new TripRequestNotFoundException;
            }

            if ($model->status !== TripRequestStatus::Pending) {
                throw new StateConflictException('Only pending trip requests can be rejected.');
            }

            $model->status = TripRequestStatus::Rejected;
            $model->rejection_reason = $rejectionReason;
            $model->handled_by = $handledBy;
            $model->handled_at = $handledAt;
            $model->save();

            return TripRequestMapper::toDomain($model->fresh()->load(['employee', 'trip.driver']));
        });
    }

    public function approveAsGroup(
        array $ids,
        string $handledBy,
        DateTimeImmutable $handledAt,
    ): array {
        return DB::transaction(function () use ($ids, $handledBy, $handledAt): array {
            $models = TripRequestModel::query()
                ->whereIn('id', $ids)
                ->orderBy('id')
                ->lockForUpdate()
                ->get();

            if ($models->count() !== count($ids)) {
                throw new TripRequestNotFoundException;
            }

            foreach ($models as $model) {
                if ($model->status !== TripRequestStatus::Pending) {
                    throw new StateConflictException(
                        'All requests in the group must be pending; operation aborted.',
                    );
                }
            }

            $suggestedGroupId = (string) Str::uuid();

            foreach ($models as $model) {
                $model->status = TripRequestStatus::Approved;
                $model->suggested_group_id = $suggestedGroupId;
                $model->handled_by = $handledBy;
                $model->handled_at = $handledAt;
                $model->approved_at = $handledAt;
                $model->save();
            }

            return $this->requestQuery()
                ->whereIn('id', $ids)
                ->orderBy('id')
                ->get()
                ->map(static fn (TripRequestModel $model): TripRequestEntity => TripRequestMapper::toDomain($model))
                ->values()
                ->all();
        });
    }

    /**
     * @return array<string, mixed>
     */
    private function attributesFromSnapshots(PlaceSnapshot $pickup, PlaceSnapshot $destination): array
    {
        return [
            'pickup_place_id' => $pickup->placeId,
            'pickup_name' => $pickup->name,
            'pickup_lat' => $pickup->lat,
            'pickup_lng' => $pickup->lng,
            'pickup_address' => $pickup->address,
            'destination_place_id' => $destination->placeId,
            'destination_name' => $destination->name,
            'destination_lat' => $destination->lat,
            'destination_lng' => $destination->lng,
            'destination_address' => $destination->address,
        ];
    }

    private function requestQuery(): mixed
    {
        return TripRequestModel::query()->with([
            'employee',
            'trip.driver.driverProfile',
            'trip.confirmedBy',
        ]);
    }

    private function applyMineBucket(mixed $query, TripRequestListBucket $bucket): void
    {
        match ($bucket) {
            TripRequestListBucket::Active => $query->where(function ($outer): void {
                $outer->where('status', TripRequestStatus::Pending->value)
                    ->orWhere(function ($approved): void {
                        $approved->where('status', TripRequestStatus::Approved->value)
                            ->where(function ($linked): void {
                                $linked->whereNull('trip_id')
                                    ->orWhereHas('trip', function ($trip): void {
                                        $trip->whereIn(
                                            'status',
                                            $this->tripStatusValues(CreatedTripListBucket::Active),
                                        );
                                    });
                            });
                    });
            }),
            TripRequestListBucket::Completed => $query
                ->where('status', TripRequestStatus::Approved->value)
                ->whereHas('trip', function ($trip): void {
                    $trip->whereIn('status', $this->tripStatusValues(CreatedTripListBucket::Completed));
                }),
            TripRequestListBucket::Cancelled => $query->where(function ($outer): void {
                $outer->whereIn('status', [
                    TripRequestStatus::Rejected->value,
                    TripRequestStatus::Cancelled->value,
                ])->orWhere(function ($approved): void {
                    $approved->where('status', TripRequestStatus::Approved->value)
                        ->whereHas('trip', function ($trip): void {
                            $trip->whereIn('status', $this->tripStatusValues(CreatedTripListBucket::Cancelled));
                        });
                });
            }),
        };
    }

    /**
     * @return list<string>
     */
    private function tripStatusValues(CreatedTripListBucket $bucket): array
    {
        return array_map(
            static fn (TripStatus $status): string => $status->value,
            $bucket->statuses(),
        );
    }

    private function applyCommonFilters(
        mixed $query,
        ?TripRequestStatus $status,
        ?DateTimeImmutable $dateFrom,
        ?DateTimeImmutable $dateTo,
    ): void {
        if ($status !== null) {
            $query->where('status', $status->value);
        }

        if ($dateFrom !== null) {
            $query->where('requested_at', '>=', $dateFrom);
        }

        if ($dateTo !== null) {
            $query->where('requested_at', '<=', $dateTo);
        }
    }

    /**
     * @param  LengthAwarePaginator<int, TripRequestModel>  $paginator
     * @return PaginatedResult<TripRequestEntity>
     */
    private function toPaginated(mixed $paginator): PaginatedResult
    {
        /** @var list<TripRequestEntity> $items */
        $items = collect($paginator->items())
            ->map(static fn (TripRequestModel $model): TripRequestEntity => TripRequestMapper::toDomain($model))
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
