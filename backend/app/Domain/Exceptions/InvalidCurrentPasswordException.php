<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class InvalidCurrentPasswordException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('The current password is incorrect.');
    }
}
