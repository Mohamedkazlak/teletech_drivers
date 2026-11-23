<?php

declare(strict_types=1);

namespace App\Application\TripRequests\DTOs;

final readonly class ConfirmTripData
{
    public function __construct(
        public string $requestId,
        public string $actorId,
        public bool $driverShowedUp,
        public ?string $note,
    ) {}
}
