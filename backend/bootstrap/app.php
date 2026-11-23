<?php

declare(strict_types=1);

use App\Console\Commands\AutoConfirmTripsCommand;
use App\Console\Commands\SeedDevUsersCommand;
use App\Domain\Exceptions\ActiveHeadquartersExistsException;
use App\Domain\Exceptions\AttendanceRejectedException;
use App\Domain\Exceptions\CannotActOnSelfException;
use App\Domain\Exceptions\CannotDeleteHeadquartersPlaceException;
use App\Domain\Exceptions\DriverLocationNotFoundException;
use App\Domain\Exceptions\InactiveUserException;
use App\Domain\Exceptions\InvalidCredentialsException;
use App\Domain\Exceptions\InvalidCurrentPasswordException;
use App\Domain\Exceptions\InvalidDriverForAssignmentException;
use App\Domain\Exceptions\InvalidDriverLocationTripException;
use App\Domain\Exceptions\InvalidFavoritePlacesException;
use App\Domain\Exceptions\InvalidTripStatusTransitionException;
use App\Domain\Exceptions\LocationAccuracyExceededException;
use App\Domain\Exceptions\NotificationNotFoundException;
use App\Domain\Exceptions\PlaceMissingCoordinatesException;
use App\Domain\Exceptions\PlaceNotFoundException;
use App\Domain\Exceptions\RequestedAtMustBeFutureException;
use App\Domain\Exceptions\SamePickupAndDestinationException;
use App\Domain\Exceptions\StateConflictException;
use App\Domain\Exceptions\TripNotFoundException;
use App\Domain\Exceptions\TripRequestNotFoundException;
use App\Domain\Exceptions\UserNotFoundException;
use App\Http\Middleware\EnsureUserHasRole;
use App\Http\Middleware\EnsureUserIsActive;
use App\Http\Middleware\SetLocaleFromHeader;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withBroadcasting(
        __DIR__.'/../routes/channels.php',
        ['prefix' => 'api', 'middleware' => ['auth:sanctum', 'active']],
    )
    ->withCommands([
        AutoConfirmTripsCommand::class,
        SeedDevUsersCommand::class,
    ])
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'role' => EnsureUserHasRole::class,
            'active' => EnsureUserIsActive::class,
        ]);
        $middleware->prependToGroup('api', SetLocaleFromHeader::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(function (Request $request, Throwable $e): bool {
            return $request->is('api/*') || $request->expectsJson();
        });

        $exceptions->render(function (ValidationException $e, Request $request) {
            if (! $request->is('api/*') && ! $request->expectsJson()) {
                return null;
            }

            return response()->json([
                'message' => 'The given data was invalid.',
                'errors' => $e->errors(),
            ], 422);
        });

        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if (! $request->is('api/*') && ! $request->expectsJson()) {
                return null;
            }

            return response()->json([
                'message' => 'Unauthenticated.',
            ], 401);
        });

        $exceptions->render(function (AuthorizationException $e, Request $request) {
            if (! $request->is('api/*') && ! $request->expectsJson()) {
                return null;
            }

            return response()->json([
                'message' => 'Forbidden.',
            ], 403);
        });

        $exceptions->render(function (ModelNotFoundException|NotFoundHttpException $e, Request $request) {
            if (! $request->is('api/*') && ! $request->expectsJson()) {
                return null;
            }

            return response()->json([
                'message' => 'Resource not found.',
            ], 404);
        });

        $exceptions->render(function (InvalidCurrentPasswordException $e, Request $request) {
            return response()->json([
                'message' => 'The given data was invalid.',
                'errors' => [
                    'current_password' => [$e->getMessage()],
                ],
            ], 422);
        });

        $exceptions->render(function (InvalidCredentialsException $e, Request $request) {
            return response()->json([
                'message' => $e->getMessage(),
            ], 401);
        });

        $exceptions->render(function (InactiveUserException $e, Request $request) {
            return response()->json([
                'message' => $e->getMessage(),
            ], 401);
        });

        $exceptions->render(function (
            UserNotFoundException|
            PlaceNotFoundException|
            TripRequestNotFoundException|
            TripNotFoundException|
            DriverLocationNotFoundException|
            NotificationNotFoundException $e,
            Request $request,
        ) {
            return response()->json([
                'message' => $e->getMessage(),
            ], 404);
        });

        $exceptions->render(function (
            StateConflictException|InvalidTripStatusTransitionException $e,
            Request $request,
        ) {
            return response()->json([
                'message' => $e->getMessage(),
            ], 409);
        });

        $exceptions->render(function (
            ActiveHeadquartersExistsException|
            CannotDeleteHeadquartersPlaceException|
            InvalidFavoritePlacesException|
            CannotActOnSelfException|
            InvalidDriverForAssignmentException|
            PlaceMissingCoordinatesException|
            SamePickupAndDestinationException|
            LocationAccuracyExceededException|
            InvalidDriverLocationTripException $e,
            Request $request,
        ) {
            return response()->json([
                'message' => $e->getMessage(),
                'errors' => [
                    'general' => [$e->getMessage()],
                ],
            ], 422);
        });

        $exceptions->render(function (AttendanceRejectedException $e, Request $request) {
            $body = [
                'message' => $e->getMessage(),
                'code' => $e->errorCode,
            ];
            if ($e->distanceM !== null) {
                $body['distance_m'] = $e->distanceM;
                $body['radius_m'] = $e->radiusM;
            }

            return response()->json($body, $e->status);
        });

        $exceptions->render(function (RequestedAtMustBeFutureException $e, Request $request) {
            $message = __('messages.scheduled_in_past');

            return response()->json([
                'message' => 'The given data was invalid.',
                'errors' => [
                    'requested_at' => [$message],
                    'scheduled_at' => [$message],
                ],
            ], 422);
        });
    })->create();
