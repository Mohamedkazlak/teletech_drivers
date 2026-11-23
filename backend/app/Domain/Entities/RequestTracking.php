<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\RequestTrackingStage;
use DateTimeImmutable;

final readonly class RequestTracking
{
    /**
     * @param  list<RequestTrackingEvent>  $timeline
     */
    public function __construct(
        public RequestTrackingStage $stage,
        public array $timeline,
        public ?string $rejectionReason,
        public ?RequestTrackingDriver $driver,
        public ?DateTimeImmutable $scheduledAt,
        public ?string $carLicense,
    ) {}
}
