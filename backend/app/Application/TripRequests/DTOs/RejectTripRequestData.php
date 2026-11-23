<?php

declare(strict_types=1);

namespace App\Application\TripRequests\DTOs;

final readonly class RejectTripRequestData
{
    public function __construct(
        public string $requestId,
        public string $handledBy,
        public ?string $rejectionReason,
    ) {}
}
