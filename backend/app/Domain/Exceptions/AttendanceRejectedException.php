<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

/**
 * A scan or attendance rule failed. [errorCode] is the stable client key.
 */
final class AttendanceRejectedException extends RuntimeException
{
    public function __construct(
        public readonly string $errorCode,
        string $message,
        public readonly int $status = 422,
        public readonly ?int $distanceM = null,
        public readonly ?int $radiusM = null,
    ) {
        parent::__construct($message);
    }
}
