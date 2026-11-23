<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Entities\Notification as NotificationEntity;
use App\Domain\Enums\NotificationType;
use App\Domain\Exceptions\NotificationNotFoundException;
use App\Domain\Repositories\NotificationRepositoryInterface;
use App\Domain\Shared\PaginatedResult;
use App\Infrastructure\Persistence\Eloquent\Mappers\NotificationMapper;
use App\Models\Notification as NotificationModel;
use DateTimeImmutable;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

final class EloquentNotificationRepository implements NotificationRepositoryInterface
{
    public function create(
        string $userId,
        NotificationType $type,
        string $titleKey,
        string $bodyKey,
        array $params,
        ?string $tripRequestId,
        ?string $tripId,
    ): NotificationEntity {
        $model = NotificationModel::query()->create([
            'user_id' => $userId,
            'type' => $type,
            'title_key' => $titleKey,
            'body_key' => $bodyKey,
            'params' => $params,
            'trip_request_id' => $tripRequestId,
            'trip_id' => $tripId,
        ]);

        return NotificationMapper::toDomain($model);
    }

    public function find(string $id): ?NotificationEntity
    {
        $model = NotificationModel::query()->find($id);

        return $model === null ? null : NotificationMapper::toDomain($model);
    }

    public function paginateForUser(
        string $userId,
        ?bool $unread,
        int $page,
        int $perPage,
    ): PaginatedResult {
        $query = NotificationModel::query()
            ->where('user_id', $userId)
            ->orderByDesc('created_at')
            ->orderByDesc('id');

        if ($unread === true) {
            $query->whereNull('read_at');
        } elseif ($unread === false) {
            $query->whereNotNull('read_at');
        }

        return $this->toPaginated($query->paginate(perPage: $perPage, page: $page));
    }

    public function unreadCount(string $userId): int
    {
        return NotificationModel::query()
            ->where('user_id', $userId)
            ->whereNull('read_at')
            ->count();
    }

    public function markRead(string $id, string $userId, DateTimeImmutable $readAt): NotificationEntity
    {
        $model = NotificationModel::query()
            ->whereKey($id)
            ->where('user_id', $userId)
            ->first();

        if ($model === null) {
            throw new NotificationNotFoundException;
        }

        if ($model->read_at === null) {
            $model->read_at = $readAt;
            $model->save();
        }

        return NotificationMapper::toDomain($model->fresh());
    }

    public function markAllRead(string $userId, DateTimeImmutable $readAt): int
    {
        $pending = NotificationModel::query()
            ->where('user_id', $userId)
            ->whereNull('read_at')
            ->get();

        foreach ($pending as $model) {
            $model->read_at = $readAt;
            $model->save();
        }

        return $pending->count();
    }

    /**
     * @param  LengthAwarePaginator<int, NotificationModel>  $paginator
     * @return PaginatedResult<NotificationEntity>
     */
    private function toPaginated(mixed $paginator): PaginatedResult
    {
        /** @var list<NotificationEntity> $items */
        $items = collect($paginator->items())
            ->map(static fn (NotificationModel $model): NotificationEntity => NotificationMapper::toDomain($model))
            ->values()
            ->all();

        return new PaginatedResult(
            items: $items,
            total: $paginator->total(),
            page: $paginator->currentPage(),
            perPage: $paginator->perPage(),
        );
    }
}
