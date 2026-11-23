<?php

declare(strict_types=1);

namespace App\Application\Notifications\DTOs;

final readonly class ListNotificationsData
{
    public function __construct(
        public string $userId,
        public ?bool $unread,
        public int $page,
        public int $perPage,
    ) {}
}
