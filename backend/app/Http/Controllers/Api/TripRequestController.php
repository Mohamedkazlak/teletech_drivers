<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\TripRequests\Actions\ApproveTripRequestAction;
use App\Application\TripRequests\Actions\ApproveTripRequestsAsGroupAction;
use App\Application\TripRequests\Actions\CancelTripRequestAction;
use App\Application\TripRequests\Actions\ConfirmTripAction;
use App\Application\TripRequests\Actions\CreateTripRequestAction;
use App\Application\TripRequests\Actions\GetGroupingSuggestionsAction;
use App\Application\TripRequests\Actions\GetTripRequestAction;
use App\Application\TripRequests\Actions\ListMineTripRequestsAction;
use App\Application\TripRequests\Actions\ListTripRequestsAction;
use App\Application\TripRequests\Actions\RejectTripRequestAction;
use App\Domain\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\TripRequests\ApproveGroupTripRequestsRequest;
use App\Http\Requests\TripRequests\ConfirmTripRequest;
use App\Http\Requests\TripRequests\ListMineTripRequestsRequest;
use App\Http\Requests\TripRequests\ListTripRequestsRequest;
use App\Http\Requests\TripRequests\RejectTripRequestRequest;
use App\Http\Requests\TripRequests\StoreTripRequestRequest;
use App\Http\Resources\GroupSuggestionResource;
use App\Http\Resources\PaginatedResourceResponse;
use App\Http\Resources\TripRequestResource;
use App\Models\TripRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class TripRequestController extends Controller
{
    public function store(StoreTripRequestRequest $request, CreateTripRequestAction $action): JsonResponse
    {
        $this->authorize('create', TripRequest::class);

        $created = $action->execute($request->toDto());

        return (new TripRequestResource($created))
            ->response()
            ->setStatusCode(201);
    }

    public function mine(ListMineTripRequestsRequest $request, ListMineTripRequestsAction $action): JsonResponse
    {
        $this->authorize('viewMine', TripRequest::class);

        $result = $action->execute($request->toDto());

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static fn ($item): TripRequestResource => new TripRequestResource($item),
                $result->items,
            ),
        );
    }

    public function index(ListTripRequestsRequest $request, ListTripRequestsAction $action): JsonResponse
    {
        $this->authorize('viewAny', TripRequest::class);

        $result = $action->execute($request->toDto());

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static fn ($item): TripRequestResource => new TripRequestResource($item),
                $result->items,
            ),
        );
    }

    public function show(string $id, GetTripRequestAction $action): TripRequestResource
    {
        $tripRequest = $action->execute($id);
        $model = TripRequest::query()->findOrFail($id);
        $this->authorize('view', $model);

        return new TripRequestResource($tripRequest);
    }

    public function cancel(string $id, CancelTripRequestAction $action): TripRequestResource
    {
        $model = TripRequest::query()->findOrFail($id);
        $this->authorize('cancel', $model);

        return new TripRequestResource($action->execute($id));
    }

    public function approve(string $id, Request $request, ApproveTripRequestAction $action): TripRequestResource
    {
        $model = TripRequest::query()->findOrFail($id);
        $this->authorize('approve', $model);

        /** @var User $user */
        $user = $request->user();

        return new TripRequestResource($action->execute($id, (string) $user->id));
    }

    public function confirm(ConfirmTripRequest $request, ConfirmTripAction $action): TripRequestResource
    {
        $model = TripRequest::query()->findOrFail((string) $request->route('id'));
        $this->authorize('confirm', $model);

        return new TripRequestResource($action->execute($request->toDto()));
    }

    public function reject(RejectTripRequestRequest $request, RejectTripRequestAction $action): TripRequestResource
    {
        $model = TripRequest::query()->findOrFail((string) $request->route('id'));
        $this->authorize('reject', $model);

        return new TripRequestResource($action->execute($request->toDto()));
    }

    public function approveGroup(
        ApproveGroupTripRequestsRequest $request,
        ApproveTripRequestsAsGroupAction $action,
    ): JsonResponse {
        $this->authorize('approveGroup', TripRequest::class);

        $items = $action->execute($request->toDto());

        return response()->json([
            'data' => array_map(
                static fn ($item): array => (new TripRequestResource($item))->resolve(),
                $items,
            ),
        ]);
    }

    public function groupingSuggestions(Request $request, GetGroupingSuggestionsAction $action): JsonResponse
    {
        $this->authorize('viewGroupingSuggestions', TripRequest::class);

        /** @var User $user */
        $user = $request->user();
        $role = $user->role instanceof UserRole ? $user->role : UserRole::from((string) $user->role);

        $suggestions = $action->execute($role);

        return response()->json([
            'data' => array_map(
                static fn ($item): array => (new GroupSuggestionResource($item))->resolve(),
                $suggestions,
            ),
        ]);
    }
}
