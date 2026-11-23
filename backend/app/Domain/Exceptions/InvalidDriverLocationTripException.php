<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class InvalidDriverLocationTripException extends RuntimeException
{
    public function __construct(string $message = 'trip_id must belong to an in-progress trip of this driver.')
    {
        parent::__construct($message);
    }
}
