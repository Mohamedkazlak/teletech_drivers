<?php

declare(strict_types=1);

namespace App\Application\Places\Actions;

use App\Application\Places\DTOs\CreatePlaceData;
use App\Domain\Entities\Place;
use App\Domain\Repositories\PlaceRepositoryInterface;

final class CreatePlaceAction
{
    public function __construct(
        private readonly PlaceRepositoryInterface $places,
    ) {}

    public function execute(CreatePlaceData $data): Place
    {
        return $this->places->create(
            nameEn: $data->nameEn,
            nameAr: $data->nameAr,
            latitude: $data->latitude,
            longitude: $data->longitude,
            address: $data->address,
            isHeadquarters: $data->isHeadquarters,
            isActive: $data->isActive,
        );
    }
}
