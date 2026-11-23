<?php

declare(strict_types=1);

namespace App\Application\Employees\DTOs;

use App\Domain\Enums\Branch;

final readonly class CreateEmployeeData
{
    public function __construct(
        public string $nameEn,
        public string $nameAr,
        public string $email,
        public string $password,
        public ?string $phone,
        public ?Branch $branch,
    ) {}
}
