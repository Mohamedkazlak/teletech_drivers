<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use DateTimeImmutable;

final readonly class GroupSuggestionMember
{
    public function __construct(
        public string $requestId,
        public ?string $requesterNameEn,
        public ?string $requesterNameAr,
        public ?string $branch,
        public string $fromPlace,
        public string $toPlace,
        public DateTimeImmutable $requestedAt,
    ) {}
}
