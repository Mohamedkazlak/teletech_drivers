<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class InvalidFavoritePlacesException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('One or more favorite places are invalid or inactive.');
    }
}
