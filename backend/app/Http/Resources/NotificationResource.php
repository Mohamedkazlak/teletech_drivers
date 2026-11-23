<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Application\Notifications\NotificationCopy;
use App\Domain\Entities\Notification;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Notification
 */
final class NotificationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var Notification $notification */
        $notification = $this->resource;
        $copy = app(NotificationCopy::class);
        $locale = app()->getLocale();

        return [
            'id' => $notification->id,
            'type' => $notification->type->value,
            'title_key' => $notification->titleKey,
            'body_key' => $notification->bodyKey,
            'params' => $notification->params,
            'title' => $copy->title($notification, $locale),
            'body' => $copy->body($notification, $locale),
            'trip_request_id' => $notification->tripRequestId,
            'trip_id' => $notification->tripId,
            'read_at' => $notification->readAt?->format(DATE_ATOM),
            'created_at' => $notification->createdAt->format(DATE_ATOM),
        ];
    }
}
