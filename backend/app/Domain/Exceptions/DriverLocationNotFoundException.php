<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class DriverLocationNotFoundException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Driver location not found.');
    }
}
