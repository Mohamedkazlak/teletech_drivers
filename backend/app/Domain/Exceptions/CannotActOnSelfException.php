<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class CannotActOnSelfException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('You cannot perform this action on yourself.');
    }
}
