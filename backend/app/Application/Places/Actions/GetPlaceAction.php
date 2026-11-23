<?php

declare(strict_types=1);

namespace App\Application\Places\Actions;

use App\Domain\Entities\Place;
use App\Domain\Exceptions\PlaceNotFoundException;
use App\Domain\Repositories\PlaceRepositoryInterface;

final class GetPlaceAction
{
    public function __construct(
        private readonly PlaceRepositoryInterface $places,
    ) {}

    public function execute(string $id): Place
    {
        $place = $this->places->findById($id);

        if ($place === null) {
            throw new PlaceNotFoundException;
        }

        return $place;
    }
}
