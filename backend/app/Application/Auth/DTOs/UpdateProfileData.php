<?php

declare(strict_types=1);

namespace App\Application\Auth\DTOs;

final readonly class UpdateProfileData
{
    /**
     * @param  array<string, mixed>  $changes  Present profile fields only.
     */
    public function __construct(
        public string $userId,
        public array $changes,
    ) {}
}
