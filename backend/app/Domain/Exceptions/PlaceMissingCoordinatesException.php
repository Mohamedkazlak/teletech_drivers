<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class PlaceMissingCoordinatesException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Selected place must have coordinates.');
    }
}
