<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;

final readonly class LinkedTrip
{
    public function __construct(
        public string $id,
        public TripStatus $status,
        public ?string $driverNameEn,
        public ?string $driverNameAr,
        public ?TripConfirmationStatus $confirmationStatus,
        public ?bool $driverShowedUp,
    ) {}
}
