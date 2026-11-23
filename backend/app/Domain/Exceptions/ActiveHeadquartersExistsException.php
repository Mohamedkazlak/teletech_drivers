<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class ActiveHeadquartersExistsException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Only one active headquarters place is allowed.');
    }
}
