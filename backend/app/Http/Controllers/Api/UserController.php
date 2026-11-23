<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\Users\Actions\ListUsersAction;
use App\Application\Users\Actions\ResetUserPasswordAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\Users\ListUsersRequest;
use App\Http\Requests\Users\ResetUserPasswordRequest;
use App\Http\Resources\AccountResource;
use App\Http\Resources\PaginatedResourceResponse;
use App\Models\User;
use Illuminate\Http\JsonResponse;

final class UserController extends Controller
{
    public function index(ListUsersRequest $request, ListUsersAction $action): JsonResponse
    {
        $this->authorize('viewAnyUsers', User::class);

        $result = $action->execute($request->toDto());

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static fn ($user): AccountResource => new AccountResource($user),
                $result->items,
            ),
        );
    }

    public function resetPassword(
        ResetUserPasswordRequest $request,
        string $id,
        ResetUserPasswordAction $action,
    ): AccountResource {
        $target = User::query()->findOrFail($id);
        $this->authorize('resetPassword', $target);

        /** @var User $actor */
        $actor = $request->user();

        return new AccountResource($action->execute(
            $request->toDto((string) $actor->getAuthIdentifier(), $id),
        ));
    }
}
