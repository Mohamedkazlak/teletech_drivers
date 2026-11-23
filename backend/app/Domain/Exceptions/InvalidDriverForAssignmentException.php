<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class InvalidDriverForAssignmentException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Driver must be an active, non-deleted user with the driver role.');
    }
}
