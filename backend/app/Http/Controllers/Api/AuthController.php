<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\Auth\Actions\ChangePasswordAction;
use App\Application\Auth\Actions\GetCurrentUserAction;
use App\Application\Auth\Actions\LoginUserAction;
use App\Application\Auth\Actions\LogoutUserAction;
use App\Application\Auth\Actions\RegisterUserAction;
use App\Application\Auth\Actions\UpdateProfileAction;
use App\Application\Drivers\Actions\GetDriverStatsAction;
use App\Application\Drivers\Actions\GetOwnDriverProfileAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ChangePasswordRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\UpdateProfileRequest;
use App\Http\Requests\Drivers\DriverStatsRequest;
use App\Http\Resources\AuthTokenResource;
use App\Http\Resources\DriverResource;
use App\Http\Resources\DriverStatsResource;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class AuthController extends Controller
{
    public function register(RegisterRequest $request, RegisterUserAction $action): JsonResponse
    {
        $result = $action->execute($request->toDto());

        return (new AuthTokenResource($result))
            ->response()
            ->setStatusCode(201);
    }

    public function login(LoginRequest $request, LoginUserAction $action): AuthTokenResource
    {
        return new AuthTokenResource($action->execute($request->toDto()));
    }

    public function logout(Request $request, LogoutUserAction $action): JsonResponse
    {
        $action->execute((string) $request->user()->getAuthIdentifier());

        return response()->json([
            'message' => 'Logged out successfully.',
        ]);
    }

    public function changePassword(ChangePasswordRequest $request, ChangePasswordAction $action): UserResource
    {
        return new UserResource($action->execute($request->toDto()));
    }

    public function me(Request $request, GetCurrentUserAction $action): UserResource
    {
        $user = $action->execute((string) $request->user()->getAuthIdentifier());

        return new UserResource($user);
    }

    public function updateMe(UpdateProfileRequest $request, UpdateProfileAction $action): UserResource
    {
        return new UserResource($action->execute($request->toDto()));
    }

    public function myStats(DriverStatsRequest $request, GetDriverStatsAction $action): DriverStatsResource
    {
        $this->authorize('viewOwnStats', User::class);

        return new DriverStatsResource($action->execute(
            (string) $request->user()->getAuthIdentifier(),
            $request->period(),
            $request->anchorDate(),
        ));
    }

    public function myDriverProfile(Request $request, GetOwnDriverProfileAction $action): DriverResource
    {
        $this->authorize('viewOwnDriverProfile', User::class);

        return new DriverResource(
            $action->execute((string) $request->user()->getAuthIdentifier()),
        );
    }
}
