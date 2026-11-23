<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Entities\TrackingPoint;
use App\Domain\Entities\Trip;
use App\Domain\Entities\TripReport;
use App\Domain\Specifications\InProgressTripSpecification;
use DateTimeImmutable;

/**
 * Factory: builds a TripReport view-model from a Trip (mirrors Flutter).
 * Partial trips never fail — missing segments are null.
 */
final class TripReportBuilder
{
    public function __construct(
        private readonly InProgressTripSpecification $inProgress = new InProgressTripSpecification,
        private readonly TrackingRouteSampler $routes = new TrackingRouteSampler,
    ) {}

    /**
     * @param  list<TrackingPoint>  $trackingPoints
     */
    public function build(Trip $trip, array $trackingPoints = []): TripReport
    {
        $startedAt = $trip->goingStartedAt;
        $finishedAt = $trip->finishedAt;
        $goingEndedAt = $trip->goingEndedAt;
        $returnStartedAt = $trip->returnStartedAt;

        return new TripReport(
            status: $trip->status,
            isInProgress: $this->inProgress->isSatisfiedBy($trip->status),
            startedAt: $startedAt,
            finishedAt: $finishedAt,
            totalDurationSeconds: $this->durationSeconds($startedAt, $finishedAt),
            goingDurationSeconds: $this->durationSeconds($startedAt, $goingEndedAt),
            waitingDurationSeconds: $this->durationSeconds($goingEndedAt, $returnStartedAt),
            returnDurationSeconds: $this->durationSeconds($returnStartedAt, $finishedAt),
            goingDistanceKm: $this->metersToKm($trip->goingDistanceM),
            returnDistanceKm: $this->metersToKm($trip->returnDistanceM),
            totalDistanceKm: $this->metersToKm($trip->totalDistanceM),
            goingRoute: $trip->goingRoute,
            returnRoute: $trip->returnRoute,
            drivenRoute: $this->routes->cap($trackingPoints),
        );
    }

    private function durationSeconds(?DateTimeImmutable $start, ?DateTimeImmutable $end): ?int
    {
        if ($start === null || $end === null) {
            return null;
        }

        $delta = $end->getTimestamp() - $start->getTimestamp();
        if ($delta < 0) {
            return null;
        }

        return $delta;
    }

    private function metersToKm(?int $meters): ?float
    {
        if ($meters === null) {
            return null;
        }

        return $meters / 1000.0;
    }
}
