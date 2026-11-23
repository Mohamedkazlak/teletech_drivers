<?php

declare(strict_types=1);

namespace App\Application\Push\Contracts;

use App\Application\Push\FcmMessageException;

interface FcmClient
{
    /**
     * False when FIREBASE_CREDENTIALS is empty or the JSON file is missing.
     */
    public function isConfigured(): bool;

    /**
     * @param  array<string, mixed>  $message  FCM HTTP v1 `message` object.
     *
     * @throws FcmMessageException
     */
    public function send(array $message): void;
}
