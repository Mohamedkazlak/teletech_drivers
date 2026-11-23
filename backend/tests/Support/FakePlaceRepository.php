<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Domain\Entities\Place;
use App\Domain\Exceptions\CannotDeleteHeadquartersPlaceException;
use App\Domain\Exceptions\PlaceNotFoundException;
use App\Domain\Repositories\PlaceRepositoryInterface;
use App\Domain\Services\HeadquartersUniqueness;
use App\Domain\Shared\PaginatedResult;
use Illuminate\Support\Str;

final class FakePlaceRepository implements PlaceRepositoryInterface
{
    /** @var array<string, Place> */
    private array $byId = [];

    public function __construct(
        private readonly HeadquartersUniqueness $headquartersUniqueness = new HeadquartersUniqueness,
    ) {}

    public function findById(string $id): ?Place
    {
        return $this->byId[$id] ?? null;
    }

    public function findActiveHeadquarters(): ?Place
    {
        foreach ($this->byId as $place) {
            if ($place->isHeadquarters && $place->isActive) {
                return $place;
            }
        }

        return null;
    }

    public function activeHeadquartersExists(?string $excludingPlaceId = null): bool
    {
        foreach ($this->byId as $place) {
            if ($excludingPlaceId !== null && $place->id === $excludingPlaceId) {
                continue;
            }

            if ($place->isHeadquarters && $place->isActive) {
                return true;
            }
        }

        return false;
    }

    public function allExistAndActive(array $placeIds): bool
    {
        foreach (array_unique($placeIds) as $id) {
            $place = $this->byId[$id] ?? null;
            if ($place === null || ! $place->isActive) {
                return false;
            }
        }

        return true;
    }

    public function paginate(
        ?bool $isActive,
        ?string $search,
        ?bool $isHeadquarters,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $items = array_values(array_filter(
            $this->byId,
            function (Place $place) use ($isActive, $search, $isHeadquarters): bool {
                if ($isActive !== null && $place->isActive !== $isActive) {
                    return false;
                }

                if ($isHeadquarters !== null && $place->isHeadquarters !== $isHeadquarters) {
                    return false;
                }

                if ($search !== null && $search !== '') {
                    $haystack = strtolower($place->nameEn.' '.$place->nameAr);
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
        ?float $latitude,
        ?float $longitude,
        ?string $address,
        bool $isHeadquarters,
        bool $isActive,
    ): Place {
        if ($isHeadquarters && $isActive) {
            $this->headquartersUniqueness->assertCanBecomeHeadquarters(
                $this->activeHeadquartersExists(),
            );
        }

        $place = new Place(
            id: (string) Str::uuid(),
            nameEn: $nameEn,
            nameAr: $nameAr,
            latitude: $latitude,
            longitude: $longitude,
            address: $address,
            isHeadquarters: $isHeadquarters,
            isActive: $isActive,
        );

        $this->byId[$place->id] = $place;

        return $place;
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
    ): Place {
        $existing = $this->byId[$id] ?? null;

        if ($existing === null) {
            throw new PlaceNotFoundException;
        }

        if ($isHeadquarters && $isActive) {
            $this->headquartersUniqueness->assertCanBecomeHeadquarters(
                $this->activeHeadquartersExists($id),
            );
        }

        $place = new Place(
            id: $id,
            nameEn: $nameEn,
            nameAr: $nameAr,
            latitude: $latitude,
            longitude: $longitude,
            address: $address,
            isHeadquarters: $isHeadquarters,
            isActive: $isActive,
            createdAt: $existing->createdAt,
        );

        $this->byId[$id] = $place;

        return $place;
    }

    public function delete(string $id): Place
    {
        $place = $this->byId[$id] ?? null;

        if ($place === null) {
            throw new PlaceNotFoundException;
        }

        if ($place->isHeadquarters) {
            throw new CannotDeleteHeadquartersPlaceException;
        }

        unset($this->byId[$id]);

        return $place;
    }

    public function seed(Place $place): void
    {
        $this->byId[$place->id] = $place;
    }
}
