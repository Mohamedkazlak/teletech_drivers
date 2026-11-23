<?php

declare(strict_types=1);

namespace App\Application\Notifications\Actions;

use App\Domain\Repositories\NotificationRepositoryInterface;

final class UnreadNotificationCountAction
{
    public function __construct(private readonly NotificationRepositoryInterface $notifications) {}

    public function execute(string $userId): int
    {
        return $this->notifications->unreadCount($userId);
    }
}
