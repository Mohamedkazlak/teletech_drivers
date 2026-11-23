<?php

declare(strict_types=1);

namespace App\Domain\Repositories;

use App\Domain\Entities\Notification;
use App\Domain\Enums\NotificationType;
use App\Domain\Shared\PaginatedResult;
use DateTimeImmutable;

interface NotificationRepositoryInterface
{
    /**
     * @param  array<string, mixed>  $params
     */
    public function create(
        string $userId,
        NotificationType $type,
        string $titleKey,
        string $bodyKey,
        array $params,
        ?string $tripRequestId,
        ?string $tripId,
    ): Notification;

    /**
     * @return PaginatedResult<Notification>
     */
    public function paginateForUser(
        string $userId,
        ?bool $unread,
        int $page,
        int $perPage,
    ): PaginatedResult;

    public function find(string $id): ?Notification;

    public function unreadCount(string $userId): int;

    public function markRead(string $id, string $userId, DateTimeImmutable $readAt): Notification;

    public function markAllRead(string $userId, DateTimeImmutable $readAt): int;
}
