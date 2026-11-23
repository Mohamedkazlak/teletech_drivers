<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\Notifications\Actions\ListNotificationsAction;
use App\Application\Notifications\Actions\MarkAllNotificationsReadAction;
use App\Application\Notifications\Actions\MarkNotificationReadAction;
use App\Application\Notifications\Actions\UnreadNotificationCountAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\Notifications\ListNotificationsRequest;
use App\Http\Resources\NotificationResource;
use App\Http\Resources\PaginatedResourceResponse;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class NotificationController extends Controller
{
    public function index(ListNotificationsRequest $request, ListNotificationsAction $action): JsonResponse
    {
        $this->authorize('viewAny', Notification::class);

        $result = $action->execute($request->toDto());

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static fn ($item): NotificationResource => new NotificationResource($item),
                $result->items,
            ),
        );
    }

    public function unreadCount(Request $request, UnreadNotificationCountAction $action): JsonResponse
    {
        $this->authorize('viewAny', Notification::class);

        /** @var User $user */
        $user = $request->user();

        return response()->json([
            'count' => $action->execute((string) $user->id),
        ]);
    }

    public function read(string $id, Request $request, MarkNotificationReadAction $action): NotificationResource
    {
        $notification = Notification::query()->findOrFail($id);
        $this->authorize('markRead', $notification);

        /** @var User $user */
        $user = $request->user();

        return new NotificationResource($action->execute($id, (string) $user->id));
    }

    public function readAll(Request $request, MarkAllNotificationsReadAction $action): JsonResponse
    {
        $this->authorize('viewAny', Notification::class);

        /** @var User $user */
        $user = $request->user();

        return response()->json([
            'updated' => $action->execute((string) $user->id),
        ]);
    }
}
