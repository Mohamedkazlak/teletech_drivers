<?php

declare(strict_types=1);

namespace App\Application\TripRequests\DTOs;

use App\Domain\Enums\UserRole;
use DateTimeImmutable;

final readonly class CreateTripRequestData
{
    public function __construct(
        public string $actorId,
        public UserRole $actorRole,
        public PlaceInputData $pickup,
        public PlaceInputData $destination,
        public DateTimeImmutable $requestedAt,
        public string $notes,
    ) {}
}
