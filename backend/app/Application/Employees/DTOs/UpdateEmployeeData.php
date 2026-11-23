<?php

declare(strict_types=1);

namespace App\Application\Employees\DTOs;

use App\Domain\Enums\Branch;

final readonly class UpdateEmployeeData
{
    public function __construct(
        public string $id,
        public string $nameEn,
        public ?string $nameAr,
        public ?string $phone,
        public ?Branch $branch,
        public bool $isActive,
        public ?string $password,
    ) {}
}
