<?php

declare(strict_types=1);

namespace App\Providers;

use App\Application\Contracts\PasswordHasherInterface;
use App\Application\Contracts\TokenIssuerInterface;
use App\Application\Push\Contracts\FcmClient;
use App\Domain\Repositories\AdminDashboardRepositoryInterface;
use App\Domain\Repositories\DeviceTokenRepositoryInterface;
use App\Domain\Repositories\DriverLocationRepositoryInterface;
use App\Domain\Repositories\DriverRepositoryInterface;
use App\Domain\Repositories\NotificationRepositoryInterface;
use App\Domain\Repositories\PlaceRepositoryInterface;
use App\Domain\Repositories\TripRepositoryInterface;
use App\Domain\Repositories\TripRequestRepositoryInterface;
use App\Domain\Repositories\UserRepositoryInterface;
use App\Domain\Services\AttendanceCalendar;
use App\Domain\Services\AttendanceClock;
use App\Domain\Services\AttendanceQr;
use App\Domain\Services\AttendanceScanGuard;
use App\Domain\Services\DriverRecommendationService;
use App\Domain\Services\DriverScheduleConflict;
use App\Domain\Services\FleetPeriodRange;
use App\Domain\Services\GeoDistance;
use App\Domain\Services\HqDistanceClassifier;
use App\Domain\Services\PolylineValidator;
use App\Domain\Services\ScheduleTime;
use App\Domain\Services\StatsAggregator;
use App\Domain\Services\Trip\TripLocationSummarizer;
use App\Domain\Services\TripReportBuilder;
use App\Domain\Services\TripRequest\CreateTripRequestStrategyFactory;
use App\Domain\Services\TripStatusTransitions;
use App\Infrastructure\Auth\LaravelPasswordHasher;
use App\Infrastructure\Auth\SanctumTokenIssuer;
use App\Infrastructure\Persistence\Eloquent\EloquentAdminDashboardRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentDeviceTokenRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentDriverLocationRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentDriverRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentNotificationRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentPlaceRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentTripRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentTripRequestRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentUserRepository;
use App\Infrastructure\Push\HttpFcmClient;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(UserRepositoryInterface::class, EloquentUserRepository::class);
        $this->app->bind(PlaceRepositoryInterface::class, EloquentPlaceRepository::class);
        $this->app->bind(DriverRepositoryInterface::class, EloquentDriverRepository::class);
        $this->app->bind(TripRequestRepositoryInterface::class, EloquentTripRequestRepository::class);
        $this->app->bind(TripRepositoryInterface::class, EloquentTripRepository::class);
        $this->app->bind(DriverLocationRepositoryInterface::class, EloquentDriverLocationRepository::class);
        $this->app->bind(AdminDashboardRepositoryInterface::class, EloquentAdminDashboardRepository::class);
        $this->app->bind(NotificationRepositoryInterface::class, EloquentNotificationRepository::class);
        $this->app->bind(DeviceTokenRepositoryInterface::class, EloquentDeviceTokenRepository::class);
        $this->app->singleton(FcmClient::class, HttpFcmClient::class);
        $this->app->bind(PasswordHasherInterface::class, LaravelPasswordHasher::class);
        $this->app->bind(TokenIssuerInterface::class, SanctumTokenIssuer::class);
        $this->app->singleton(TripStatusTransitions::class);
        $this->app->singleton(CreateTripRequestStrategyFactory::class);
        $this->app->singleton(TripLocationSummarizer::class);
        $this->app->singleton(TripReportBuilder::class);
        $this->app->singleton(FleetPeriodRange::class, static fn (): FleetPeriodRange => FleetPeriodRange::fromConfig());
        $this->app->singleton(GeoDistance::class);
        $this->app->singleton(HqDistanceClassifier::class, static fn (): HqDistanceClassifier => HqDistanceClassifier::fromConfig());
        $this->app->singleton(DriverScheduleConflict::class, static fn (): DriverScheduleConflict => DriverScheduleConflict::fromConfig());
        $this->app->singleton(PolylineValidator::class, static fn (): PolylineValidator => PolylineValidator::fromConfig());
        $this->app->singleton(AttendanceClock::class, static fn (): AttendanceClock => AttendanceClock::fromConfig());
        $this->app->singleton(AttendanceCalendar::class);
        $this->app->singleton(AttendanceQr::class);
        $this->app->singleton(AttendanceScanGuard::class);
        $this->app->singleton(DriverRecommendationService::class);
        $this->app->singleton(StatsAggregator::class);
        $this->app->singleton(ScheduleTime::class, static fn (): ScheduleTime => ScheduleTime::fromConfig());
    }

    public function boot(): void
    {
        JsonResource::withoutWrapping();

        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip() ?? 'unknown');
        });

        RateLimiter::for('driver-location', function (Request $request) {
            $perMinute = (int) config('teletech.driver_location_throttle_per_minute', 12);
            $key = $request->user()?->id ?? ($request->ip() ?? 'unknown');

            return Limit::perMinute($perMinute)->by((string) $key);
        });
    }
}
