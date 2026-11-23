<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Exceptions\ActiveHeadquartersExistsException;

/**
 * Ensures at most one active headquarters place exists.
 * Strategy: reject a second active HQ with a domain exception (HTTP 422).
 * Does not atomically replace the previous headquarters.
 */
final class HeadquartersUniqueness
{
    public function assertCanBecomeHeadquarters(bool $activeHeadquartersAlreadyExists): void
    {
        if ($activeHeadquartersAlreadyExists) {
            throw new ActiveHeadquartersExistsException;
        }
    }
}
