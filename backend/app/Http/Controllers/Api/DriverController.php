<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\Drivers\Actions\CountDriverTripsThisWeekAction;
use App\Application\Drivers\Actions\CreateDriverAction;
use App\Application\Drivers\Actions\ExportDriverMovementReportAction;
use App\Application\Drivers\Actions\GetDriverAction;
use App\Application\Drivers\Actions\GetDriverStatsAction;
use App\Application\Drivers\Actions\ListDriverCompletedTripsAction;
use App\Application\Drivers\Actions\ListDriversAction;
use App\Application\Drivers\Actions\RestoreDriverAction;
use App\Application\Drivers\Actions\SoftDeleteDriverAction;
use App\Application\Drivers\Actions\UpdateDriverAction;
use App\Domain\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Drivers\DriverStatsRequest;
use App\Http\Requests\Drivers\ExportDriverReportRequest;
use App\Http\Requests\Drivers\ListDriverCompletedTripsRequest;
use App\Http\Requests\Drivers\ListDriversRequest;
use App\Http\Requests\Drivers\StoreDriverRequest;
use App\Http\Requests\Drivers\UpdateDriverRequest;
use App\Http\Resources\DriverCompletedTripResource;
use App\Http\Resources\DriverResourceFactory;
use App\Http\Resources\DriverStatsResource;
use App\Http\Resources\PaginatedResourceResponse;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Symfony\Component\HttpFoundation\Response;

final class DriverController extends Controller
{
    public function __construct(
        private readonly DriverResourceFactory $driverResources,
    ) {}

    public function index(
        ListDriversRequest $request,
        ListDriversAction $action,
        CountDriverTripsThisWeekAction $weekTrips,
    ): JsonResponse {
        $this->authorize('viewAnyDrivers', User::class);

        /** @var User $actor */
        $actor = $request->user();
        $result = $action->execute($request->toDto());
        $ids = [];
        foreach ($result->items as $driver) {
            $ids[] = $driver->user->id;
        }

        return PaginatedResourceResponse::make(
            $result,
            $this->driverResources->makeMany(
                $result->items,
                $actor,
                $weekTrips->execute($ids),
            ),
        );
    }

    public function store(StoreDriverRequest $request, CreateDriverAction $action): JsonResponse
    {
        $this->authorize('createDriver', User::class);

        /** @var User $actor */
        $actor = $request->user();
        $driver = $action->execute($request->toDto());

        return $this->driverResources->make($driver, $actor)
            ->response()
            ->setStatusCode(201);
    }

    public function show(
        Request $request,
        string $id,
        GetDriverAction $action,
        GetDriverStatsAction $stats,
        CountDriverTripsThisWeekAction $weekTrips,
    ): JsonResource {
        $target = $this->findDriverModel($id);
        $this->authorize('viewDriver', $target);

        /** @var User $actor */
        $actor = $request->user();

        return $this->driverResources->make(
            $action->execute($id),
            $actor,
            $stats->execute($id, 'all', null),
            $weekTrips->execute([$id])[$id] ?? 0,
        );
    }

    public function exportReport(
        ExportDriverReportRequest $request,
        string $id,
        ExportDriverMovementReportAction $action,
    ): Response {
        $target = $this->findDriverModel($id);
        $this->authorize('exportMovementReport', $target);

        $period = $request->period();
        $date = $request->anchorDate();
        $filename = 'driver-report-'.$id.'-'.$period.'-'.$date.'.pdf';

        return response($action->pdf($id, $period, $date, $request->project()), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="'.$filename.'"',
        ]);
    }

    public function stats(DriverStatsRequest $request, string $id, GetDriverStatsAction $action): DriverStatsResource
    {
        $target = $this->findDriverModel($id);
        $this->authorize('viewDriverActivity', $target);

        return new DriverStatsResource($action->execute($id, $request->period(), $request->anchorDate()));
    }

    public function trips(
        ListDriverCompletedTripsRequest $request,
        string $id,
        ListDriverCompletedTripsAction $action,
    ): JsonResponse {
        $target = $this->findDriverModel($id);
        $this->authorize('viewDriverActivity', $target);

        $result = $action->execute($request->toDto());

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static fn ($item): DriverCompletedTripResource => new DriverCompletedTripResource($item),
                $result->items,
            ),
        );
    }

    public function update(UpdateDriverRequest $request, UpdateDriverAction $action): JsonResource
    {
        $target = $this->findDriverModel((string) $request->route('id'));
        $this->authorize('updateDriver', $target);

        /** @var User $actor */
        $actor = $request->user();

        $driver = $action->execute($request->toDto());

        return $this->driverResources->make($driver, $actor);
    }

    public function destroy(Request $request, string $id, SoftDeleteDriverAction $action): JsonResource
    {
        $target = $this->findDriverModel($id);
        $this->authorize('deleteDriver', $target);

        /** @var User $actor */
        $actor = $request->user();
        $driver = $action->execute($id, (string) $actor->getAuthIdentifier());

        return $this->driverResources->make($driver, $actor);
    }

    public function restore(Request $request, string $id, RestoreDriverAction $action): JsonResource
    {
        $target = $this->findDriverModel($id, withTrashed: true);
        $this->authorize('restoreDriver', $target);

        /** @var User $actor */
        $actor = $request->user();

        $driver = $action->execute($id);

        return $this->driverResources->make($driver, $actor);
    }

    private function findDriverModel(string $id, bool $withTrashed = false): User
    {
        $query = User::query()->where('role', UserRole::Driver);

        if ($withTrashed) {
            $query->withTrashed();
        }

        return $query->findOrFail($id);
    }
}
