<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class InactiveUserException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('This account is inactive.');
    }
}
