<?php

declare(strict_types=1);

namespace App\Application\Notifications\Actions;

use App\Domain\Entities\Notification;
use App\Domain\Repositories\NotificationRepositoryInterface;
use DateTimeImmutable;
use Illuminate\Support\Facades\DB;

final class MarkNotificationReadAction
{
    public function __construct(private readonly NotificationRepositoryInterface $notifications) {}

    public function execute(string $id, string $userId): Notification
    {
        return DB::transaction(function () use ($id, $userId): Notification {
            return $this->notifications->markRead($id, $userId, DateTimeImmutable::createFromInterface(now()));
        });
    }
}
