<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Services\FleetPeriodRange;
use DateTimeImmutable;
use DateTimeZone;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

final class FleetPeriodRangeTest extends TestCase
{
    private DateTimeZone $cairo;

    protected function setUp(): void
    {
        parent::setUp();
        $this->cairo = new DateTimeZone('Africa/Cairo');
    }

    public function test_week_starts_on_saturday_and_contains_the_anchor_day(): void
    {
        $range = $this->saturdayWeeks()->containing('week', '2026-11-04');

        $this->assertSame('Saturday', $range['start']->format('l'));
        $this->assertSame('2026-10-31', $range['start']->format('Y-m-d'));
        $this->assertSame('00:00:00', $range['start']->format('H:i:s'));
        $this->assertSame('Africa/Cairo', $range['start']->getTimezone()->getName());
        $this->assertSame('2026-11-07', $range['end_exclusive']->format('Y-m-d'));
        $this->assertSame('Saturday', $range['end_exclusive']->format('l'));
    }

    public function test_saturday_and_friday_belong_to_the_same_week(): void
    {
        $saturday = $this->saturdayWeeks()->containing('week', '2026-10-31');
        $friday = $this->saturdayWeeks()->containing('week', '2026-11-06');

        $this->assertSame('2026-10-31', $saturday['start']->format('Y-m-d'));
        $this->assertSame('2026-11-07', $saturday['end_exclusive']->format('Y-m-d'));
        $this->assertEquals($saturday, $friday);
    }

    public function test_sunday_belongs_to_the_week_that_started_the_previous_saturday(): void
    {
        $range = $this->saturdayWeeks()->containing('week', '2026-11-01');

        $this->assertSame('2026-10-31', $range['start']->format('Y-m-d'));
        $this->assertSame('2026-11-07', $range['end_exclusive']->format('Y-m-d'));
    }

    public function test_week_start_follows_the_configured_weekday(): void
    {
        $range = (new FleetPeriodRange($this->cairo, 'Monday'))->containing('week', '2026-11-04');

        $this->assertSame('Monday', $range['start']->format('l'));
        $this->assertSame('2026-11-02', $range['start']->format('Y-m-d'));
        $this->assertSame('2026-11-09', $range['end_exclusive']->format('Y-m-d'));
    }

    public function test_month_and_year_use_cairo_calendar_boundaries(): void
    {
        $weeks = $this->saturdayWeeks();
        $month = $weeks->containing('month', '2026-11-04');
        $year = $weeks->containing('year', '2026-11-04');

        $this->assertSame('2026-11-01T00:00:00+02:00', $month['start']->format(DATE_ATOM));
        $this->assertSame('2026-12-01T00:00:00+02:00', $month['end_exclusive']->format(DATE_ATOM));
        $this->assertSame('2026-01-01T00:00:00+02:00', $year['start']->format(DATE_ATOM));
        $this->assertSame('2027-01-01T00:00:00+02:00', $year['end_exclusive']->format(DATE_ATOM));
    }

    public function test_timestamp_is_placed_by_its_cairo_calendar_day(): void
    {
        $range = $this->saturdayWeeks()->containing('month', '2026-10-31T22:30:00Z');

        $this->assertSame('2026-11-01', $range['start']->format('Y-m-d'));
        $this->assertSame('2026-12-01', $range['end_exclusive']->format('Y-m-d'));
    }

    public function test_omitted_date_uses_the_supplied_now_in_cairo(): void
    {
        $now = new DateTimeImmutable('2026-11-04 22:30:00', new DateTimeZone('UTC'));
        $range = $this->saturdayWeeks()->containing('week', null, $now);

        $this->assertSame('2026-10-31', $range['start']->format('Y-m-d'));
        $this->assertSame('2026-11-07', $range['end_exclusive']->format('Y-m-d'));
    }

    public function test_day_is_the_cairo_calendar_day(): void
    {
        $range = $this->saturdayWeeks()->containing('day', '2026-11-06T22:30:00Z');

        $this->assertSame('2026-11-07T00:00:00+02:00', $range['start']->format(DATE_ATOM));
        $this->assertSame('2026-11-08T00:00:00+02:00', $range['end_exclusive']->format(DATE_ATOM));
    }

    public function test_invalid_period_is_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->saturdayWeeks()->containing('fortnight', '2026-11-04');
    }

    public function test_invalid_week_start_name_is_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);
        (new FleetPeriodRange($this->cairo, 'Funday'))->containing('week', '2026-11-04');
    }

    private function saturdayWeeks(): FleetPeriodRange
    {
        return new FleetPeriodRange($this->cairo, 'Saturday');
    }
}
