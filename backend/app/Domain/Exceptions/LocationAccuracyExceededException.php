<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class LocationAccuracyExceededException extends RuntimeException
{
    public function __construct(float $accuracy, float $maxAllowed)
    {
        parent::__construct(
            sprintf(
                'Location accuracy %.1f m exceeds the allowed maximum of %.1f m.',
                $accuracy,
                $maxAllowed,
            ),
        );
    }
}
