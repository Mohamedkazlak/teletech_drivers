<?php

declare(strict_types=1);

namespace App\Application\Notifications\Actions;

use App\Domain\Repositories\NotificationRepositoryInterface;
use DateTimeImmutable;
use Illuminate\Support\Facades\DB;

final class MarkAllNotificationsReadAction
{
    public function __construct(private readonly NotificationRepositoryInterface $notifications) {}

    public function execute(string $userId): int
    {
        return DB::transaction(function () use ($userId): int {
            return $this->notifications->markAllRead($userId, DateTimeImmutable::createFromInterface(now()));
        });
    }
}
