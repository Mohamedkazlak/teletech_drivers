<?php

declare(strict_types=1);

namespace App\Application\Employees\DTOs;

use App\Domain\Enums\Branch;

final readonly class ListEmployeesData
{
    public function __construct(
        public ?bool $isActive,
        public ?Branch $branch,
        public ?string $search,
        public bool $includeDeleted,
        public int $page = 1,
        public int $perPage = 15,
    ) {}
}
