<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Entities\Place as PlaceEntity;
use App\Domain\Exceptions\CannotDeleteHeadquartersPlaceException;
use App\Domain\Exceptions\PlaceNotFoundException;
use App\Domain\Repositories\PlaceRepositoryInterface;
use App\Domain\Services\HeadquartersUniqueness;
use App\Domain\Shared\PaginatedResult;
use App\Infrastructure\Persistence\Eloquent\Mappers\PlaceMapper;
use App\Models\Place as PlaceModel;
use Illuminate\Support\Facades\DB;

final class EloquentPlaceRepository implements PlaceRepositoryInterface
{
    public function __construct(
        private readonly HeadquartersUniqueness $headquartersUniqueness,
    ) {}

    public function findById(string $id): ?PlaceEntity
    {
        $model = PlaceModel::query()->find($id);

        return $model === null ? null : PlaceMapper::toDomain($model);
    }

    public function findActiveHeadquarters(): ?PlaceEntity
    {
        $model = PlaceModel::query()
            ->where('is_headquarters', true)
            ->where('is_active', true)
            ->first();

        return $model === null ? null : PlaceMapper::toDomain($model);
    }

    public function activeHeadquartersExists(?string $excludingPlaceId = null): bool
    {
        $query = PlaceModel::query()
            ->where('is_headquarters', true)
            ->where('is_active', true);

        if ($excludingPlaceId !== null) {
            $query->where('id', '!=', $excludingPlaceId);
        }

        return $query->exists();
    }

    public function allExistAndActive(array $placeIds): bool
    {
        if ($placeIds === []) {
            return true;
        }

        $uniqueIds = array_values(array_unique($placeIds));

        $count = PlaceModel::query()
            ->whereIn('id', $uniqueIds)
            ->where('is_active', true)
            ->count();

        return $count === count($uniqueIds);
    }

    public function paginate(
        ?bool $isActive,
        ?string $search,
        ?bool $isHeadquarters,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $query = PlaceModel::query()->orderBy('name_en');

        if ($isActive !== null) {
            $query->where('is_active', $isActive);
        }

        if ($isHeadquarters !== null) {
            $query->where('is_headquarters', $isHeadquarters);
        }

        if ($search !== null && $search !== '') {
            $query->where(function ($builder) use ($search): void {
                $builder
                    ->where('name_en', 'like', '%'.$search.'%')
                    ->orWhere('name_ar', 'like', '%'.$search.'%');
            });
        }

        $paginator = $query->paginate(perPage: $perPage, page: $page);

        /** @var list<PlaceEntity> $items */
        $items = collect($paginator->items())
            ->map(fn (PlaceModel $model): PlaceEntity => PlaceMapper::toDomain($model))
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
        ?float $latitude,
        ?float $longitude,
        ?string $address,
        bool $isHeadquarters,
        bool $isActive,
    ): PlaceEntity {
        if ($isHeadquarters && $isActive) {
            $this->headquartersUniqueness->assertCanBecomeHeadquarters(
                $this->activeHeadquartersExists(),
            );
        }

        $model = PlaceModel::query()->create([
            'name_en' => $nameEn,
            'name_ar' => $nameAr,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'address' => $address,
            'is_headquarters' => $isHeadquarters,
            'is_active' => $isActive,
        ]);

        return PlaceMapper::toDomain($model);
    }

    public function update(
        string $id,
        string $nameEn,
        string $nameAr,
        ?float $latitude,
        ?float $longitude,
        ?string $address,
        bool $isHeadquarters,
        bool $isActive,
    ): PlaceEntity {
        $model = PlaceModel::query()->find($id);

        if ($model === null) {
            throw new PlaceNotFoundException;
        }

        if ($isHeadquarters && $isActive) {
            $this->headquartersUniqueness->assertCanBecomeHeadquarters(
                $this->activeHeadquartersExists($id),
            );
        }

        $model->fill([
            'name_en' => $nameEn,
            'name_ar' => $nameAr,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'address' => $address,
            'is_headquarters' => $isHeadquarters,
            'is_active' => $isActive,
        ]);
        $model->save();

        return PlaceMapper::toDomain($model->fresh());
    }

    public function delete(string $id): PlaceEntity
    {
        $model = PlaceModel::query()->find($id);

        if ($model === null) {
            throw new PlaceNotFoundException;
        }

        if ($model->is_headquarters) {
            throw new CannotDeleteHeadquartersPlaceException;
        }

        DB::transaction(function () use ($model): void {
            $model->favoritedByDrivers()->detach();
            $model->delete();
        });

        return PlaceMapper::toDomain($model);
    }
}
