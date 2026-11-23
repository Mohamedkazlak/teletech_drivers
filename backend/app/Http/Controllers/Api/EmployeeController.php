<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\Employees\Actions\CreateEmployeeAction;
use App\Application\Employees\Actions\GetEmployeeAction;
use App\Application\Employees\Actions\ListEmployeesAction;
use App\Application\Employees\Actions\RestoreEmployeeAction;
use App\Application\Employees\Actions\SoftDeleteEmployeeAction;
use App\Application\Employees\Actions\UpdateEmployeeAction;
use App\Domain\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Employees\ListEmployeesRequest;
use App\Http\Requests\Employees\StoreEmployeeRequest;
use App\Http\Requests\Employees\UpdateEmployeeRequest;
use App\Http\Resources\EmployeeResource;
use App\Http\Resources\PaginatedResourceResponse;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class EmployeeController extends Controller
{
    public function index(ListEmployeesRequest $request, ListEmployeesAction $action): JsonResponse
    {
        $this->authorize('viewAnyEmployees', User::class);

        $result = $action->execute($request->toDto());

        return PaginatedResourceResponse::make(
            $result,
            array_map(
                static fn ($user): EmployeeResource => new EmployeeResource($user),
                $result->items,
            ),
        );
    }

    public function store(StoreEmployeeRequest $request, CreateEmployeeAction $action): JsonResponse
    {
        $this->authorize('createEmployee', User::class);

        $employee = $action->execute($request->toDto());

        return (new EmployeeResource($employee))
            ->response()
            ->setStatusCode(201);
    }

    public function show(string $id, GetEmployeeAction $action): EmployeeResource
    {
        $target = $this->findEmployeeModel($id);
        $this->authorize('viewEmployee', $target);

        return new EmployeeResource($action->execute($id));
    }

    public function update(UpdateEmployeeRequest $request, UpdateEmployeeAction $action): EmployeeResource
    {
        $target = $this->findEmployeeModel((string) $request->route('id'));
        $this->authorize('updateEmployee', $target);

        return new EmployeeResource($action->execute($request->toDto()));
    }

    public function destroy(Request $request, string $id, SoftDeleteEmployeeAction $action): EmployeeResource
    {
        $target = $this->findEmployeeModel($id);
        $this->authorize('deleteEmployee', $target);

        /** @var User $actor */
        $actor = $request->user();

        return new EmployeeResource(
            $action->execute($id, (string) $actor->getAuthIdentifier()),
        );
    }

    public function restore(string $id, RestoreEmployeeAction $action): EmployeeResource
    {
        $target = $this->findEmployeeModel($id, withTrashed: true);
        $this->authorize('restoreEmployee', $target);

        return new EmployeeResource($action->execute($id));
    }

    private function findEmployeeModel(string $id, bool $withTrashed = false): User
    {
        $query = User::query()->where('role', UserRole::Employee);

        if ($withTrashed) {
            $query->withTrashed();
        }

        return $query->findOrFail($id);
    }
}
