<?php

declare(strict_types=1);

namespace App\Application\Push\Actions;

use App\Domain\Repositories\DeviceTokenRepositoryInterface;

final class DeleteDeviceTokenAction
{
    public function __construct(private readonly DeviceTokenRepositoryInterface $tokens) {}

    public function execute(string $userId, string $token): void
    {
        $this->tokens->deleteForUser($userId, $token);
    }
}
