<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\Push\Actions\DeleteDeviceTokenAction;
use App\Application\Push\Actions\UpsertDeviceTokenAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\DeviceTokens\DeleteDeviceTokenRequest;
use App\Http\Requests\DeviceTokens\UpsertDeviceTokenRequest;
use App\Models\User;
use Illuminate\Http\Response;

final class DeviceTokenController extends Controller
{
    public function store(UpsertDeviceTokenRequest $request, UpsertDeviceTokenAction $action): Response
    {
        /** @var User $user */
        $user = $request->user();

        $action->execute(
            userId: (string) $user->id,
            token: $request->token(),
            platform: $request->platform(),
            locale: app()->getLocale(),
        );

        return response()->noContent();
    }

    public function destroy(DeleteDeviceTokenRequest $request, DeleteDeviceTokenAction $action): Response
    {
        /** @var User $user */
        $user = $request->user();

        $action->execute((string) $user->id, $request->token());

        return response()->noContent();
    }
}
