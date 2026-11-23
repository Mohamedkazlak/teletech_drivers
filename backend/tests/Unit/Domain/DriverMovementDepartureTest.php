<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Entities\AvailabilityPresence;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Reports\DriverMovementRow;
use App\Domain\Reports\MovementTripStop;
use App\Domain\Services\DriverDayAttendance;
use App\Domain\Services\DriverMovementReportBuilder;
use App\Domain\Services\FleetPeriodRange;
use DateTimeImmutable;
use DateTimeZone;
use PHPUnit\Framework\TestCase;

final class DriverMovementDepartureTest extends TestCase
{
    private DateTimeZone $cairo;

    private DriverMovementReportBuilder $builder;

    protected function setUp(): void
    {
        parent::setUp();
        $this->cairo = new DateTimeZone('Africa/Cairo');
        $this->builder = new DriverMovementReportBuilder(
            new FleetPeriodRange($this->cairo, 'Saturday'),
            new DriverDayAttendance,
        );
    }

    public function test_default_departure_is_seventeen_hundred(): void
    {
        $this->assertSame('17:00', DriverDayAttendance::DEFAULT_DEPARTURE);
    }

    public function test_signature_names_are_fixed_right_to_left(): void
    {
        $this->assertSame([
            'أ/ احمد علي',
            'أ/ احمد الحاج',
            'العقيد/ ياسر ابو العنين',
            'م/ عمرو عبدالله',
        ], DriverMovementReportBuilder::SIGNATURES);
    }

    public function test_the_default_starts_at_the_next_cairo_midnight(): void
    {
        $events = [
            new AvailabilityPresence('driver', AvailabilityStatus::Available, $this->at('2026-09-08 08:00:00')),
        ];

        $open = $this->row('2026-09-08', $this->at('2026-09-08 23:59:59'), [], $events);
        $this->assertSame('', $open->departure);
        $this->assertFalse($open->departureIsDefault);

        $closed = $this->row('2026-09-08', $this->at('2026-09-09 00:00:00'), [], $events);
        $this->assertSame('5.00', $closed->departure);
        $this->assertTrue($closed->departureIsDefault);
    }

    /**
     * @param  list<MovementTripStop>  $trips
     * @param  list<AvailabilityPresence>  $events
     */
    private function row(string $date, DateTimeImmutable $now, array $trips, array $events): DriverMovementRow
    {
        $pages = $this->builder->pages('week', $date, $trips, $events, $now);
        foreach ($pages[0]->rows as $row) {
            if ($row->leading && $row->date === $this->at($date.' 00:00:00')->format('d-M-y')) {
                return $row;
            }
        }

        $this->fail('Missing leading row for '.$date);
    }

    private function at(string $wallClock): DateTimeImmutable
    {
        return new DateTimeImmutable($wallClock, $this->cairo);
    }
}
