<?php

declare(strict_types=1);

namespace App\Application\Push;

use RuntimeException;

final class FcmMessageException extends RuntimeException
{
    public function __construct(
        public readonly ?string $errorCode,
        string $message,
    ) {
        parent::__construct($message);
    }
}
