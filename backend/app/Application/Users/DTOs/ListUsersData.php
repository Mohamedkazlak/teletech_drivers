<?php

declare(strict_types=1);

namespace App\Application\Users\DTOs;

use App\Domain\Enums\UserRole;

final readonly class ListUsersData
{
    public function __construct(
        public ?UserRole $role,
        public ?string $search,
        public int $page,
        public int $perPage,
    ) {}
}
