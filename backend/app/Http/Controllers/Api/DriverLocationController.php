<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\DriverLocations\Actions\GetLiveMapAction;
use App\Application\DriverLocations\Actions\PublishDriverLocationAction;
use App\Application\DriverLocations\Actions\StopDriverLocationAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\DriverLocations\LiveMapRequest;
use App\Http\Requests\DriverLocations\PublishDriverLocationRequest;
use App\Http\Resources\DriverLocationResource;
use App\Http\Resources\LiveMapDriverResource;
use App\Models\DriverLocation;
use App\Models\User;
use Illuminate\Http\JsonResponse;

final class DriverLocationController extends Controller
{
    public function upsert(
        PublishDriverLocationRequest $request,
        PublishDriverLocationAction $action,
    ): DriverLocationResource {
        $this->authorize('publish', DriverLocation::class);

        return new DriverLocationResource($action->execute($request->toDto()));
    }

    public function stop(StopDriverLocationAction $action): DriverLocationResource
    {
        $this->authorize('stop', DriverLocation::class);

        /** @var User $user */
        $user = request()->user();

        return new DriverLocationResource($action->execute($user->id));
    }

    public function liveMap(LiveMapRequest $request, GetLiveMapAction $action): JsonResponse
    {
        $this->authorize('viewLiveMap', DriverLocation::class);

        $items = $action->execute($request->driverId(), $request->attendance());

        return response()->json([
            'data' => array_map(
                static fn ($item): array => (new LiveMapDriverResource($item))->resolve(),
                $items,
            ),
        ]);
    }
}
