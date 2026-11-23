<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\Trips\Actions\ArriveAtDestinationAction;
use App\Application\Trips\Actions\AssignDriverAction;
use App\Application\Trips\Actions\CancelTripAction;
use App\Application\Trips\Actions\CreateTripsFromRequestsAction;
use App\Application\Trips\Actions\EndTripAction;
use App\Application\Trips\Actions\GetDriverRecommendationsAction;
use App\Application\Trips\Actions\GetTripAction;
use App\Application\Trips\Actions\GetTripReportAction;
use App\Application\Trips\Actions\ListCreatedByMeTripsAction;
use App\Application\Trips\Actions\ListMineTripsAction;
use App\Application\Trips\Actions\ListMyTripsAction;
use App\Application\Trips\Actions\ListTripsAction;
use App\Application\Trips\Actions\StartReturnAction;
use App\Application\Trips\Actions\StartTripAction;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\TripNotFoundException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Trips\ArriveAtDestinationRequest;
use App\Http\Requests\Trips\AssignDriverRequest;
use App\Http\Requests\Trips\CreateTripsFromRequestsRequest;
use App\Http\Requests\Trips\EndTripRequest;
use App\Http\Requests\Trips\ListCreatedByMeTripsRequest;
use App\Http\Requests\Trips\ListMineTripsRequest;
use App\Http\Requests\Trips\ListTripsRequest;
use App\Http\Requests\Trips\StartTripRequest;
use App\Http\Resources\DriverRecommendationResource;
use App\Http\Resources\PaginatedResourceResponse;
use App\Http\Resources\TripReportResource;
use App\Http\Resources\TripResourceFactory;
use App\Models\Trip;
use App\Models\User;
use App\Policies\TripPolicy;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\JsonResource;

final class TripController extends Controller
{
    public function fromRequests(
        CreateTripsFromRequestsRequest $request,
        CreateTripsFromRequestsAction $action,
    ): JsonResponse {
        $this->authorize('createFromRequests', Trip::class);

        /** @var User $user */
        $user = $request->user();
        $trips = $action->execute($request->toDto());

        return response()->json([
            'data' => array_map(
                static function ($trip) use ($user): array {
                    $model = Trip::query()->findOrFail($trip->id);

                    return TripResourceFactory::make($user, $trip, $model)->resolve();
                },
                $trips,
            ),
        ], 201);
    }

    public function index(ListTripsRequest $request, ListTripsAction $action): JsonResponse
    {
        $this->authorize('viewAny', Trip::class);

        /** @var User $user */
        $user = $request->user();
        $result = $action->execute($request->toDto(), $user->role, (string) $user->id);

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static function ($trip) use ($user): JsonResource {
                    $model = new Trip;
                    $model->id = $trip->id;
                    $model->driver_id = $trip->driverId;
                    $model->exists = true;

                    return TripResourceFactory::make($user, $trip, $model);
                },
                $result->items,
            ),
        );
    }

    public function myTrips(ListTripsRequest $request, ListMyTripsAction $action): JsonResponse
    {
        $this->authorize('viewMyTrips', Trip::class);

        /** @var User $user */
        $user = $request->user();
        $result = $action->execute((string) $user->id, $user->role, $request->toDto());
        $limitToViewer = $user->role !== UserRole::Driver;

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static function ($trip) use ($user, $limitToViewer): JsonResource {
                    $model = new Trip;
                    $model->id = $trip->id;
                    $model->driver_id = $trip->driverId;
                    $model->exists = true;

                    return TripResourceFactory::make($user, $trip, $model, $limitToViewer);
                },
                $result->items,
            ),
        );
    }

    public function mine(ListMineTripsRequest $request, ListMineTripsAction $action): JsonResponse
    {
        $this->authorize('viewMine', Trip::class);

        /** @var User $user */
        $user = $request->user();
        $result = $action->execute($request->toDto());

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static function ($trip) use ($user): JsonResource {
                    $model = new Trip;
                    $model->id = $trip->id;
                    $model->driver_id = $trip->driverId;
                    $model->exists = true;

                    return TripResourceFactory::make($user, $trip, $model);
                },
                $result->items,
            ),
        );
    }

    public function createdByMe(
        ListCreatedByMeTripsRequest $request,
        ListCreatedByMeTripsAction $action,
    ): JsonResponse {
        $this->authorize('viewCreatedByMe', Trip::class);

        /** @var User $user */
        $user = $request->user();
        $result = $action->execute($request->toDto());

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static function ($trip) use ($user): JsonResource {
                    $model = new Trip;
                    $model->id = $trip->id;
                    $model->driver_id = $trip->driverId;
                    $model->exists = true;

                    return TripResourceFactory::make($user, $trip, $model);
                },
                $result->items,
            ),
        );
    }

    public function show(string $id, GetTripAction $action): JsonResource
    {
        $trip = $action->execute($id);
        $model = Trip::query()->findOrFail($id);
        $this->authorize('view', $model);

        /** @var User $user */
        $user = request()->user();

        return TripResourceFactory::make($user, $trip, $model);
    }

    public function assign(AssignDriverRequest $request, AssignDriverAction $action): JsonResource
    {
        $model = Trip::query()->findOrFail((string) $request->route('id'));
        $this->authorize('assign', $model);

        /** @var User $user */
        $user = $request->user();
        $trip = $action->execute($request->toDto());
        $fresh = Trip::query()->findOrFail($trip->id);

        return TripResourceFactory::make($user, $trip, $fresh);
    }

    public function cancel(string $id, CancelTripAction $action): JsonResource
    {
        $model = Trip::query()->findOrFail($id);
        $this->authorize('cancel', $model);

        /** @var User $user */
        $user = request()->user();
        $trip = $action->execute($id);
        $fresh = Trip::query()->findOrFail($trip->id);

        return TripResourceFactory::make($user, $trip, $fresh);
    }

    public function start(StartTripRequest $request, StartTripAction $action): JsonResource
    {
        $model = Trip::query()->findOrFail((string) $request->route('id'));
        $this->authorize('drive', $model);

        /** @var User $user */
        $user = $request->user();
        $trip = $action->execute($request->toDto());
        $fresh = Trip::query()->findOrFail($trip->id);

        return TripResourceFactory::make($user, $trip, $fresh);
    }

    public function arrive(ArriveAtDestinationRequest $request, ArriveAtDestinationAction $action): JsonResource
    {
        $model = Trip::query()->findOrFail((string) $request->route('id'));
        $this->authorize('drive', $model);

        /** @var User $user */
        $user = $request->user();
        $trip = $action->execute($request->toDto());
        $fresh = Trip::query()->findOrFail($trip->id);

        return TripResourceFactory::make($user, $trip, $fresh);
    }

    public function startReturn(string $id, StartReturnAction $action): JsonResource
    {
        $model = Trip::query()->findOrFail($id);
        $this->authorize('drive', $model);

        /** @var User $user */
        $user = request()->user();
        $trip = $action->execute($id);
        $fresh = Trip::query()->findOrFail($trip->id);

        return TripResourceFactory::make($user, $trip, $fresh);
    }

    public function end(EndTripRequest $request, EndTripAction $action): JsonResource
    {
        $model = Trip::query()->findOrFail((string) $request->route('id'));
        $this->authorize('drive', $model);

        /** @var User $user */
        $user = $request->user();
        $trip = $action->execute($request->toDto());
        $fresh = Trip::query()->findOrFail($trip->id);

        return TripResourceFactory::make($user, $trip, $fresh);
    }

    public function report(string $id, GetTripReportAction $action): TripReportResource
    {
        $model = Trip::query()->find($id);
        if ($model === null) {
            throw new TripNotFoundException;
        }

        /** @var User $user */
        $user = request()->user();
        if ((new TripPolicy)->reportIsOutsideScope($user, $model)) {
            throw new TripNotFoundException;
        }

        $this->authorize('viewReport', $model);

        return new TripReportResource($action->execute($id));
    }

    public function driverRecommendations(
        string $id,
        GetDriverRecommendationsAction $action,
    ): JsonResponse {
        $model = Trip::query()->findOrFail($id);
        $this->authorize('viewDriverRecommendations', $model);

        $items = $action->execute($id);

        return response()->json([
            'data' => array_map(
                static fn ($item): array => (new DriverRecommendationResource($item))->resolve(),
                $items,
            ),
        ]);
    }
}
