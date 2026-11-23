<?php

declare(strict_types=1);

namespace App\Domain\Exceptions;

use RuntimeException;

final class NotificationNotFoundException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('Notification not found.');
    }
}
