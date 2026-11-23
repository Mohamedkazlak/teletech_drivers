<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class SamePickupAndDestinationException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Pickup and destination must be different.');
    }
}
