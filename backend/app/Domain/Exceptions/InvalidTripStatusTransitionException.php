<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use App\Domain\Enums\TripStatus;
use RuntimeException;

final class InvalidTripStatusTransitionException extends RuntimeException
{
    public function __construct(TripStatus $from, TripStatus $to)
    {
        parent::__construct(
            sprintf(
                'Trip status cannot transition from %s to %s.',
                $from->value,
                $to->value,
            ),
        );
    }
}
