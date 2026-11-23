<?php

declare(strict_types=1);

namespace App\Domain\Entities;

final readonly class Driver
{
    /**
     * @param  list<string>  $favoritePlaceIds
     */
    public function __construct(
        public User $user,
        public string $nationalId,
        public string $carLicense,
        public string $personalLicense,
        public array $favoritePlaceIds,
        public ?int $checkInDistanceM = null,
    ) {}
}
