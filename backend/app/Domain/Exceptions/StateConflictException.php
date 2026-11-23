<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class StateConflictException extends RuntimeException
{
    public function __construct(string $message)
    {
        parent::__construct($message);
    }
}
