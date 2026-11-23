<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use DateTimeImmutable;

final readonly class User
{
    public function __construct(
        public string $id,
        public string $nameEn,
        public ?string $nameAr,
        public string $email,
        public string $passwordHash,
        public UserRole $role,
        public bool $isActive,
        public ?string $phone,
        public ?Branch $branch,
        public AvailabilityStatus $availabilityStatus,
        public ?DateTimeImmutable $availabilityUpdatedAt = null,
        public ?string $deletedAt = null,
        public ?string $deletedBy = null,
        public bool $mustChangePassword = false,
    ) {}

    public function canAuthenticate(): bool
    {
        return $this->isActive && $this->deletedAt === null;
    }

    public function isSoftDeleted(): bool
    {
        return $this->deletedAt !== null;
    }
}
