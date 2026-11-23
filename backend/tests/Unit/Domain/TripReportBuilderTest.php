<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Entities\Trip;
use App\Domain\Enums\TripStatus;
use App\Domain\Services\TripReportBuilder;
use DateTimeImmutable;
use PHPUnit\Framework\TestCase;

final class TripReportBuilderTest extends TestCase
{
    private TripReportBuilder $builder;

    protected function setUp(): void
    {
        parent::setUp();
        $this->builder = new TripReportBuilder;
    }

    public function test_complete_trip(): void
    {
        $start = new DateTimeImmutable('2026-11-03T08:00:00+00:00');
        $goingEnd = new DateTimeImmutable('2026-11-03T09:00:00+00:00');
        $returnStart = new DateTimeImmutable('2026-11-03T09:10:00+00:00');
        $finish = new DateTimeImmutable('2026-11-03T10:00:00+00:00');

        $report = $this->builder->build($this->trip(
            status: TripStatus::Completed,
            goingStartedAt: $start,
            goingEndedAt: $goingEnd,
            returnStartedAt: $returnStart,
            finishedAt: $finish,
            goingDistanceM: 12500,
            returnDistanceM: 11000,
            totalDistanceM: 23500,
            goingRoute: 'abc',
            returnRoute: 'def',
        ));

        $this->assertSame(3600, $report->goingDurationSeconds);
        $this->assertSame(600, $report->waitingDurationSeconds);
        $this->assertSame(3000, $report->returnDurationSeconds);
        $this->assertSame(7200, $report->totalDurationSeconds);
        $this->assertSame(12.5, $report->goingDistanceKm);
        $this->assertSame(11.0, $report->returnDistanceKm);
        $this->assertSame(23.5, $report->totalDistanceKm);
        $this->assertFalse($report->isInProgress);
        $this->assertSame('abc', $report->goingRoute);
    }

    public function test_partial_assigned_all_null(): void
    {
        $report = $this->builder->build($this->trip(status: TripStatus::Assigned));

        $this->assertNull($report->startedAt);
        $this->assertNull($report->goingDurationSeconds);
        $this->assertNull($report->goingDistanceKm);
        $this->assertNull($report->goingRoute);
        $this->assertFalse($report->isInProgress);
    }

    public function test_partial_going(): void
    {
        $start = new DateTimeImmutable('2026-11-03T08:00:00+00:00');
        $report = $this->builder->build($this->trip(
            status: TripStatus::Going,
            goingStartedAt: $start,
            startLat: 30.0,
            startLng: 31.0,
        ));

        $this->assertTrue($report->isInProgress);
        $this->assertSame($start->format(DATE_ATOM), $report->startedAt?->format(DATE_ATOM));
        $this->assertNull($report->goingDurationSeconds);
        $this->assertNull($report->finishedAt);
    }

    public function test_partial_at_destination_has_going_duration(): void
    {
        $start = new DateTimeImmutable('2026-11-03T08:00:00+00:00');
        $goingEnd = new DateTimeImmutable('2026-11-03T08:30:00+00:00');
        $report = $this->builder->build($this->trip(
            status: TripStatus::AtDestination,
            goingStartedAt: $start,
            goingEndedAt: $goingEnd,
            goingDistanceM: 5000,
            goingRoute: 'go',
        ));

        $this->assertSame(1800, $report->goingDurationSeconds);
        $this->assertNull($report->waitingDurationSeconds);
        $this->assertSame(5.0, $report->goingDistanceKm);
    }

    public function test_partial_returning(): void
    {
        $start = new DateTimeImmutable('2026-11-03T08:00:00+00:00');
        $goingEnd = new DateTimeImmutable('2026-11-03T08:30:00+00:00');
        $returnStart = new DateTimeImmutable('2026-11-03T08:40:00+00:00');
        $report = $this->builder->build($this->trip(
            status: TripStatus::Returning,
            goingStartedAt: $start,
            goingEndedAt: $goingEnd,
            returnStartedAt: $returnStart,
            goingDistanceM: 5000,
            goingRoute: 'go',
        ));

        $this->assertSame(600, $report->waitingDurationSeconds);
        $this->assertNull($report->returnDurationSeconds);
        $this->assertNull($report->totalDurationSeconds);
    }

    public function test_negative_duration_becomes_null(): void
    {
        $start = new DateTimeImmutable('2026-11-03T09:00:00+00:00');
        $goingEnd = new DateTimeImmutable('2026-11-03T08:00:00+00:00');
        $report = $this->builder->build($this->trip(
            status: TripStatus::AtDestination,
            goingStartedAt: $start,
            goingEndedAt: $goingEnd,
        ));

        $this->assertNull($report->goingDurationSeconds);
    }

    private function trip(
        TripStatus $status,
        ?DateTimeImmutable $goingStartedAt = null,
        ?DateTimeImmutable $goingEndedAt = null,
        ?DateTimeImmutable $returnStartedAt = null,
        ?DateTimeImmutable $finishedAt = null,
        ?float $startLat = null,
        ?float $startLng = null,
        ?int $goingDistanceM = null,
        ?int $returnDistanceM = null,
        ?int $totalDistanceM = null,
        ?string $goingRoute = null,
        ?string $returnRoute = null,
    ): Trip {
        return new Trip(
            id: 't1',
            driverId: 'd1',
            scheduledAt: new DateTimeImmutable('2026-11-03T07:00:00+00:00'),
            status: $status,
            createdBy: 'admin',
            pickupSummary: 'P',
            destinationSummary: 'D',
            goingStartedAt: $goingStartedAt,
            goingEndedAt: $goingEndedAt,
            returnStartedAt: $returnStartedAt,
            finishedAt: $finishedAt,
            startLat: $startLat,
            startLng: $startLng,
            goingDistanceM: $goingDistanceM,
            returnDistanceM: $returnDistanceM,
            totalDistanceM: $totalDistanceM,
            goingRoute: $goingRoute,
            returnRoute: $returnRoute,
            createdAt: new DateTimeImmutable('2026-11-01T00:00:00+00:00'),
        );
    }
}
