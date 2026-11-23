<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class CannotDeleteHeadquartersPlaceException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('The headquarters place cannot be deleted.');
    }
}
