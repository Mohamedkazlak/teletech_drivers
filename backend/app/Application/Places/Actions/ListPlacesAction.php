<?php

declare(strict_types=1);

namespace App\Application\Places\Actions;

use App\Application\Places\DTOs\ListPlacesData;
use App\Domain\Entities\Place;
use App\Domain\Repositories\PlaceRepositoryInterface;
use App\Domain\Shared\PaginatedResult;

final class ListPlacesAction
{
    public function __construct(
        private readonly PlaceRepositoryInterface $places,
    ) {}

    /**
     * @return PaginatedResult<Place>
     */
    public function execute(ListPlacesData $data): PaginatedResult
    {
        return $this->places->paginate(
            isActive: $data->isActive,
            search: $data->search,
            isHeadquarters: $data->isHeadquarters,
            page: $data->page,
            perPage: $data->perPage,
        );
    }
}
