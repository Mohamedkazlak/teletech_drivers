<?php

declare(strict_types=1);

use App\Http\Controllers\Api\AdminDashboardController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\DeviceTokenController;
use App\Http\Controllers\Api\DriverController;
use App\Http\Controllers\Api\DriverLocationController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PlaceController;
use App\Http\Controllers\Api\TripController;
use App\Http\Controllers\Api\TripRequestController;
use App\Http\Controllers\Api\UserController;
use App\Http\Middleware\EnsurePasswordChangeNotRequired;
use App\Http\Middleware\EnsureUserIsActive;
use Illuminate\Support\Facades\Route;

Route::pattern('id', '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');

Route::prefix('auth')->group(function (): void {
    Route::middleware('throttle:auth')->group(function (): void {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login', [AuthController::class, 'login']);
    });

    Route::middleware(['auth:sanctum', EnsureUserIsActive::class, EnsurePasswordChangeNotRequired::class])->group(function (): void {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::post('change-password', [AuthController::class, 'changePassword'])
            ->middleware('throttle:auth');
        Route::get('me', [AuthController::class, 'me']);
        Route::get('me/stats', [AuthController::class, 'myStats']);
        Route::patch('me', [AuthController::class, 'updateMe']);
        Route::get('me/driver-profile', [AuthController::class, 'myDriverProfile']);
    });
});

Route::middleware(['auth:sanctum', EnsureUserIsActive::class, EnsurePasswordChangeNotRequired::class])->group(function (): void {
    Route::get('places', [PlaceController::class, 'index']);
    Route::get('places/{id}', [PlaceController::class, 'show']);
    Route::post('places', [PlaceController::class, 'store']);
    Route::patch('places/{id}', [PlaceController::class, 'update']);
    Route::delete('places/{id}', [PlaceController::class, 'destroy']);

    Route::get('drivers', [DriverController::class, 'index']);
    Route::post('drivers', [DriverController::class, 'store']);
    Route::get('drivers/{id}/attendance', [AttendanceController::class, 'driverHistory']);
    Route::get('drivers/{id}/stats', [DriverController::class, 'stats']);
    Route::get('drivers/{id}/report/export', [DriverController::class, 'exportReport']);
    Route::get('drivers/{id}/trips', [DriverController::class, 'trips']);
    Route::get('drivers/{id}', [DriverController::class, 'show']);
    Route::patch('drivers/{id}', [DriverController::class, 'update']);
    Route::delete('drivers/{id}', [DriverController::class, 'destroy']);
    Route::post('drivers/{id}/restore', [DriverController::class, 'restore']);

    Route::get('users', [UserController::class, 'index']);
    Route::post('users/{id}/reset-password', [UserController::class, 'resetPassword']);

    Route::get('employees', [EmployeeController::class, 'index']);
    Route::post('employees', [EmployeeController::class, 'store']);
    Route::get('employees/{id}', [EmployeeController::class, 'show']);
    Route::patch('employees/{id}', [EmployeeController::class, 'update']);
    Route::delete('employees/{id}', [EmployeeController::class, 'destroy']);
    Route::post('employees/{id}/restore', [EmployeeController::class, 'restore']);

    Route::get('admin/dashboard', [AdminDashboardController::class, 'show']);

    Route::post('device-tokens', [DeviceTokenController::class, 'store']);
    Route::delete('device-tokens', [DeviceTokenController::class, 'destroy']);

    Route::get('notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('notifications/read-all', [NotificationController::class, 'readAll']);
    Route::get('notifications', [NotificationController::class, 'index']);
    Route::post('notifications/{id}/read', [NotificationController::class, 'read']);

    Route::post('trip-requests', [TripRequestController::class, 'store']);
    Route::get('trip-requests/mine', [TripRequestController::class, 'mine']);
    Route::get('trip-requests/grouping-suggestions', [TripRequestController::class, 'groupingSuggestions']);
    Route::post('trip-requests/approve-group', [TripRequestController::class, 'approveGroup']);
    Route::get('trip-requests', [TripRequestController::class, 'index']);
    Route::get('trip-requests/{id}', [TripRequestController::class, 'show']);
    Route::post('trip-requests/{id}/cancel', [TripRequestController::class, 'cancel']);
    Route::post('trip-requests/{id}/approve', [TripRequestController::class, 'approve']);
    Route::post('trip-requests/{id}/reject', [TripRequestController::class, 'reject']);
    Route::post('trip-requests/{id}/confirm-trip', [TripRequestController::class, 'confirm']);

    Route::get('my-trips', [TripController::class, 'myTrips']);

    Route::post('trips/from-requests', [TripController::class, 'fromRequests']);
    Route::get('trips/mine', [TripController::class, 'mine']);
    Route::get('trips/created-by-me', [TripController::class, 'createdByMe']);
    Route::get('trips', [TripController::class, 'index']);
    Route::get('trips/{id}', [TripController::class, 'show']);
    Route::post('trips/{id}/assign', [TripController::class, 'assign']);
    Route::post('trips/{id}/cancel', [TripController::class, 'cancel']);
    Route::post('trips/{id}/start', [TripController::class, 'start']);
    Route::post('trips/{id}/arrive', [TripController::class, 'arrive']);
    Route::post('trips/{id}/start-return', [TripController::class, 'startReturn']);
    Route::post('trips/{id}/end', [TripController::class, 'end']);
    Route::get('trips/{id}/report', [TripController::class, 'report']);
    Route::get('trips/{id}/driver-recommendations', [TripController::class, 'driverRecommendations']);

    Route::post('attendance/check-in', [AttendanceController::class, 'checkIn']);
    Route::post('attendance/check-out', [AttendanceController::class, 'checkOut']);
    Route::get('attendance/today/summary', [AttendanceController::class, 'summary']);
    Route::get('attendance/today', [AttendanceController::class, 'today']);
    Route::get('attendance/me', [AttendanceController::class, 'mine']);
    Route::get('attendance/qr', [AttendanceController::class, 'qr']);
    Route::post('attendance/adjust', [AttendanceController::class, 'adjust']);
    Route::get('attendance', [AttendanceController::class, 'index']);

    Route::middleware('throttle:driver-location')->group(function (): void {
        Route::put('driver-location', [DriverLocationController::class, 'upsert']);
    });
    Route::post('driver-location/stop', [DriverLocationController::class, 'stop']);
    Route::get('live-map', [DriverLocationController::class, 'liveMap']);
});
