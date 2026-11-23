<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Entities\CountableTrip;
use App\Domain\Services\FleetPeriodRange;
use App\Domain\Services\StatsAggregator;
use DateTimeImmutable;
use DateTimeZone;
use PHPUnit\Framework\TestCase;

final class StatsAggregatorTest extends TestCase
{
    private DateTimeZone $cairo;

    private StatsAggregator $stats;

    protected function setUp(): void
    {
        parent::setUp();
        $this->cairo = new DateTimeZone('Africa/Cairo');
        $this->stats = new StatsAggregator(new FleetPeriodRange($this->cairo, 'Saturday'));
    }

    public function test_week_has_seven_saturday_buckets_and_cairo_edges(): void
    {
        $inside = $this->trip('2026-11-06T21:30:00+00:00', '2026-11-06T20:30:00+00:00', 2500);
        $nextWeek = $this->trip('2026-11-06T22:30:00+00:00', '2026-11-06T21:30:00+00:00', 9000);
        $justBefore = $this->trip('2026-10-30T21:59:59+00:00', '2026-10-30T21:00:00+00:00', 100);

        $result = $this->stats->aggregate('week', '2026-11-04', [$inside, $nextWeek, $justBefore]);

        $this->assertSame('week', $result->period);
        $this->assertSame('2026-10-31T00:00:00+02:00', $result->from?->format(DATE_ATOM));
        $this->assertSame('2026-11-07T00:00:00+02:00', $result->to?->format(DATE_ATOM));
        $this->assertSame(1, $result->trips);
        $this->assertSame(3600, $result->totalSeconds);
        $this->assertSame(2500, $result->totalDistanceM);
        $this->assertCount(7, $result->breakdown);
        $this->assertSame('2026-10-31', $result->breakdown[0]->label);
        $this->assertSame('Saturday', $result->breakdown[0]->from->format('l'));
        $this->assertSame('2026-11-06', $result->breakdown[6]->label);
        $this->assertSame(1, $result->breakdown[6]->trips);
        $this->assertSame(0, $result->breakdown[0]->trips);
    }

    public function test_month_and_leap_year_and_calendar_year_buckets(): void
    {
        $november = $this->stats->aggregate('month', '2026-11-04', []);
        $this->assertCount(30, $november->breakdown);
        $this->assertSame('2026-11-01', $november->breakdown[0]->label);
        $this->assertSame('2026-11-30', $november->breakdown[29]->label);

        $february = $this->stats->aggregate('month', '2024-02-10', []);
        $this->assertCount(29, $february->breakdown);
        $this->assertSame('2024-02-29', $february->breakdown[28]->label);

        $year = $this->stats->aggregate('year', '2026-11-04', [
            $this->trip('2026-03-01T10:00:00+00:00', '2026-03-01T09:00:00+00:00', null),
        ]);
        $this->assertCount(12, $year->breakdown);
        $this->assertSame('2026-01', $year->breakdown[0]->label);
        $this->assertSame('2026-12', $year->breakdown[11]->label);
        $this->assertSame(1, $year->breakdown[2]->trips);
        $this->assertSame(0, $year->breakdown[2]->totalDistanceM);
        $this->assertSame(3600, $year->totalSeconds);
    }

    public function test_all_keeps_only_years_with_trips_and_skips_missing_time(): void
    {
        $missingStart = $this->trip('2024-06-01T10:00:00+00:00', null, 1500);
        $later = $this->trip('2026-01-02T00:30:00+00:00', '2026-01-01T22:30:00+00:00', null);

        $result = $this->stats->aggregate('all', '2030-01-01', [$later, $missingStart]);

        $this->assertSame(['2024', '2026'], array_map(
            static fn ($bucket): string => $bucket->label,
            $result->breakdown,
        ));
        $this->assertSame(7200, $result->breakdown[1]->totalSeconds);
        $this->assertSame(2, $result->trips);
        $this->assertSame(7200, $result->totalSeconds);
        $this->assertSame(1500, $result->totalDistanceM);
        $this->assertSame(0, $result->breakdown[0]->totalSeconds);
        $this->assertSame(1500, $result->breakdown[0]->totalDistanceM);
        $this->assertSame('2024-01-01T00:00:00+02:00', $result->from?->format(DATE_ATOM));
        $this->assertSame('2027-01-01T00:00:00+02:00', $result->to?->format(DATE_ATOM));

        $empty = $this->stats->aggregate('all', null, []);
        $this->assertNull($empty->from);
        $this->assertNull($empty->to);
        $this->assertSame([], $empty->breakdown);
    }

    public function test_kilometers_round_to_two_decimals_and_null_meters_are_zero(): void
    {
        $this->assertSame(1.23, StatsAggregator::kilometers(1234));
        $this->assertSame(2.5, StatsAggregator::kilometers(2500));
        $this->assertSame(0.0, StatsAggregator::kilometers(null));
        $this->assertSame(0.0, StatsAggregator::kilometers(1));
    }

    public function test_duration_is_the_timestamp_difference_and_null_when_either_side_is_missing(): void
    {
        $start = new DateTimeImmutable('2026-11-04T09:00:00+00:00');
        $end = new DateTimeImmutable('2026-11-04T09:00:30+00:00');

        $this->assertSame(30, StatsAggregator::durationSeconds($start, $end));
        $this->assertSame(-30, StatsAggregator::durationSeconds($end, $start));
        $this->assertNull(StatsAggregator::durationSeconds(null, $end));
        $this->assertNull(StatsAggregator::durationSeconds($start, null));
    }

    private function trip(string $finished, ?string $started, ?int $meters): CountableTrip
    {
        return new CountableTrip(
            goingStartedAt: $started === null ? null : new DateTimeImmutable($started),
            finishedAt: new DateTimeImmutable($finished),
            totalDistanceM: $meters,
        );
    }
}
