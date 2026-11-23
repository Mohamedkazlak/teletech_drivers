<?php

declare(strict_types=1);

namespace App\Application\Places\Actions;

use App\Domain\Entities\Place;
use App\Domain\Repositories\PlaceRepositoryInterface;

final class DeletePlaceAction
{
    public function __construct(
        private readonly PlaceRepositoryInterface $places,
    ) {}

    public function execute(string $id): Place
    {
        return $this->places->delete($id);
    }
}
