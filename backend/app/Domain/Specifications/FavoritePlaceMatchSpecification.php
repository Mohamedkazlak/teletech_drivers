<?php

declare(strict_types=1);

namespace App\Domain\Specifications;

/**
 * Specification: driver's favorite_place_ids intersect trip place ids.
 */
final class FavoritePlaceMatchSpecification
{
    /**
     * @param  list<string>  $favoritePlaceIds
     * @param  list<string>  $tripPlaceIds
     */
    public function isSatisfiedBy(array $favoritePlaceIds, array $tripPlaceIds): bool
    {
        if ($favoritePlaceIds === [] || $tripPlaceIds === []) {
            return false;
        }

        $tripSet = array_fill_keys($tripPlaceIds, true);
        foreach ($favoritePlaceIds as $id) {
            if ($id !== '' && isset($tripSet[$id])) {
                return true;
            }
        }

        return false;
    }
}
