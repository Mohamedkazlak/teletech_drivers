<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\Admin\Actions\GetAdminDashboardAction;
use App\Http\Controllers\Controller;
use App\Http\Resources\AdminDashboardResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;

final class AdminDashboardController extends Controller
{
    public function show(GetAdminDashboardAction $action): JsonResponse
    {
        $this->authorize('viewAdminDashboard', User::class);

        return response()->json([
            'data' => (new AdminDashboardResource($action->execute()))->resolve(),
        ]);
    }
}
