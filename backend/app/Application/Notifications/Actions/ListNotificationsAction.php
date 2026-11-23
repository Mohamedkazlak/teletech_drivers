<?php

declare(strict_types=1);

namespace App\Application\Notifications\Actions;

use App\Application\Notifications\DTOs\ListNotificationsData;
use App\Domain\Entities\Notification;
use App\Domain\Repositories\NotificationRepositoryInterface;
use App\Domain\Shared\PaginatedResult;

final class ListNotificationsAction
{
    public function __construct(private readonly NotificationRepositoryInterface $notifications) {}

    /**
     * @return PaginatedResult<Notification>
     */
    public function execute(ListNotificationsData $data): PaginatedResult
    {
        return $this->notifications->paginateForUser(
            userId: $data->userId,
            unread: $data->unread,
            page: $data->page,
            perPage: $data->perPage,
        );
    }
}
