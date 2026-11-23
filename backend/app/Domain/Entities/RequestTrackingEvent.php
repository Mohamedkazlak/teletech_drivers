<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\RequestTrackingStage;
use App\Domain\Enums\UserRole;
use DateTimeImmutable;

final readonly class RequestTrackingEvent
{
    public function __construct(
        public RequestTrackingStage $stage,
        public ?DateTimeImmutable $reachedAt,
        public ?UserRole $actorRole,
    ) {}
}
