<?php

declare(strict_types=1);

namespace App\Domain\Repositories;

use App\Domain\Entities\Place;
use App\Domain\Shared\PaginatedResult;

interface PlaceRepositoryInterface
{
    public function findById(string $id): ?Place;

    public function findActiveHeadquarters(): ?Place;

    public function activeHeadquartersExists(?string $excludingPlaceId = null): bool;

    /**
     * @param  list<string>  $placeIds
     */
    public function allExistAndActive(array $placeIds): bool;

    /**
     * @return PaginatedResult<Place>
     */
    public function paginate(
        ?bool $isActive,
        ?string $search,
        ?bool $isHeadquarters,
        int $page,
        int $perPage,
    ): PaginatedResult;

    public function create(
        string $nameEn,
        string $nameAr,
        ?float $latitude,
        ?float $longitude,
        ?string $address,
        bool $isHeadquarters,
        bool $isActive,
    ): Place;

    public function delete(string $id): Place;

    public function update(
        string $id,
        string $nameEn,
        string $nameAr,
        ?float $latitude,
        ?float $longitude,
        ?string $address,
        bool $isHeadquarters,
        bool $isActive,
    ): Place;
}
