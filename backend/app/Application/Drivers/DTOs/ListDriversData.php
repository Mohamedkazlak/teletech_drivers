<?php

declare(strict_types=1);

namespace App\Application\Drivers\DTOs;

use App\Domain\Enums\DriverAttendanceFilter;

final readonly class ListDriversData
{
    public function __construct(
        public ?bool $isActive,
        public ?DriverAttendanceFilter $attendance,
        public ?string $search,
        public bool $includeDeleted,
        public int $page = 1,
        public int $perPage = 15,
    ) {}
}
