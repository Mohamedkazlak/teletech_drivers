<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\Places\Actions\CreatePlaceAction;
use App\Application\Places\Actions\DeletePlaceAction;
use App\Application\Places\Actions\GetPlaceAction;
use App\Application\Places\Actions\ListPlacesAction;
use App\Application\Places\Actions\UpdatePlaceAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\Places\ListPlacesRequest;
use App\Http\Requests\Places\StorePlaceRequest;
use App\Http\Requests\Places\UpdatePlaceRequest;
use App\Http\Resources\PaginatedResourceResponse;
use App\Http\Resources\PlaceResource;
use App\Models\Place;
use Illuminate\Http\JsonResponse;

final class PlaceController extends Controller
{
    public function index(ListPlacesRequest $request, ListPlacesAction $action): JsonResponse
    {
        $this->authorize('viewAny', Place::class);

        $result = $action->execute($request->toDto());

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static fn ($place): PlaceResource => new PlaceResource($place),
                $result->items,
            ),
        );
    }

    public function show(string $id, GetPlaceAction $action): PlaceResource
    {
        $place = $action->execute($id);
        $this->authorize('view', Place::query()->findOrFail($id));

        return new PlaceResource($place);
    }

    public function store(StorePlaceRequest $request, CreatePlaceAction $action): JsonResponse
    {
        $this->authorize('create', Place::class);

        $place = $action->execute($request->toDto());

        return (new PlaceResource($place))
            ->response()
            ->setStatusCode(201);
    }

    public function update(UpdatePlaceRequest $request, UpdatePlaceAction $action): PlaceResource
    {
        $model = Place::query()->findOrFail((string) $request->route('id'));
        $this->authorize('update', $model);

        return new PlaceResource($action->execute($request->toDto()));
    }

    public function destroy(string $id, DeletePlaceAction $action): PlaceResource
    {
        $place = Place::query()->findOrFail($id);
        $this->authorize('delete', $place);

        return new PlaceResource($action->execute($id));
    }
}
