<?php

declare(strict_types=1);

namespace App\Application\Places\DTOs;

final readonly class ListPlacesData
{
    public function __construct(
        public ?bool $isActive,
        public ?string $search,
        public ?bool $isHeadquarters,
        public int $page = 1,
        public int $perPage = 15,
    ) {}
}
