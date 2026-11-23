<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use App\Domain\Enums\NotificationType;
use DateTimeImmutable;

final readonly class Notification
{
    /**
     * @param  array<string, mixed>  $params
     */
    public function __construct(
        public string $id,
        public string $userId,
        public NotificationType $type,
        public string $titleKey,
        public string $bodyKey,
        public array $params,
        public ?string $tripRequestId,
        public ?string $tripId,
        public ?DateTimeImmutable $readAt,
        public DateTimeImmutable $createdAt,
    ) {}
}
