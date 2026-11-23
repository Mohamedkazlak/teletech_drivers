<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Entities\AvailabilityPresence;
use App\Domain\Reports\DriverMovementPage;
use App\Domain\Reports\DriverMovementRow;
use App\Domain\Reports\MovementTripStop;
use DateTimeImmutable;
use DateTimeZone;
use InvalidArgumentException;

/**
 * One Cairo day per block. Day number, weekday, date, arrival, and departure
 * print on the first row of that day only. Extra trips leave those cells blank.
 * A day with no trips still prints. A defaulted departure is still only on that first row.
 */
final class DriverMovementReportBuilder
{
    /**
     * Footer names, right to left. Fixed for every sheet.
     *
     * @var list<string>
     */
    public const SIGNATURES = [
        'أ/ احمد علي',
        'أ/ احمد الحاج',
        'العقيد/ ياسر ابو العنين',
        'م/ عمرو عبدالله',
    ];

    private const WEEKDAYS = [
        0 => 'الأحد',
        1 => 'الإثنين',
        2 => 'الثلاثاء',
        3 => 'الأربعاء',
        4 => 'الخميس',
        5 => 'الجمعة',
        6 => 'السبت',
    ];

    private const MONTHS = [
        1 => 'يناير',
        2 => 'فبراير',
        3 => 'مارس',
        4 => 'أبريل',
        5 => 'مايو',
        6 => 'يونيو',
        7 => 'يوليو',
        8 => 'أغسطس',
        9 => 'سبتمبر',
        10 => 'أكتوبر',
        11 => 'نوفمبر',
        12 => 'ديسمبر',
    ];

    public function __construct(
        private readonly FleetPeriodRange $periods,
        private readonly DriverDayAttendance $attendance,
    ) {}

    /**
     * @param  list<MovementTripStop>  $trips
     * @param  list<AvailabilityPresence>  $presence
     * @return list<DriverMovementPage>
     */
    public function pages(
        string $period,
        string $date,
        array $trips,
        array $presence,
        ?DateTimeImmutable $now = null,
    ): array {
        $now ??= DateTimeImmutable::createFromInterface(now());
        if (! in_array($period, ['week', 'month', 'year'], true)) {
            throw new InvalidArgumentException('Period must be week, month, or year.');
        }

        $bounds = $this->periods->containing($period, $date);
        $slices = $period === 'year'
            ? $this->months($bounds['start'], $bounds['end_exclusive'])
            : [['start' => $bounds['start'], 'end' => $bounds['end_exclusive']]];

        $tripsByDay = $this->tripsByDay($trips);
        $presenceByDay = $this->presenceByDay($presence);
        $pages = [];
        foreach ($slices as $slice) {
            $pages[] = new DriverMovementPage(
                monthLabel: $this->monthLabel($slice['start']),
                rows: $this->rows($slice['start'], $slice['end'], $tripsByDay, $presenceByDay, $now),
            );
        }

        return $pages;
    }

    /**
     * @return list<array{start: DateTimeImmutable, end: DateTimeImmutable}>
     */
    private function months(DateTimeImmutable $start, DateTimeImmutable $end): array
    {
        $slices = [];
        $cursor = $start;
        while ($cursor < $end) {
            $next = $cursor->modify('first day of next month');
            $slices[] = ['start' => $cursor, 'end' => $next];
            $cursor = $next;
        }

        return $slices;
    }

    /**
     * @param  array<string, list<MovementTripStop>>  $tripsByDay
     * @param  array<string, list<AvailabilityPresence>>  $presenceByDay
     * @return list<DriverMovementRow>
     */
    private function rows(
        DateTimeImmutable $start,
        DateTimeImmutable $end,
        array $tripsByDay,
        array $presenceByDay,
        DateTimeImmutable $now,
    ): array {
        $rows = [];
        $day = $start;
        while ($day < $end) {
            $key = $day->format('Y-m-d');
            $trips = $tripsByDay[$key] ?? [];
            usort($trips, static function (MovementTripStop $a, MovementTripStop $b): int {
                return ($a->anchor()?->getTimestamp() ?? 0) <=> ($b->anchor()?->getTimestamp() ?? 0);
            });
            $events = $presenceByDay[$key] ?? [];
            $mark = $this->attendance->departure($events, $trips !== [], $day, $now);
            $arrival = $this->clock($this->attendance->arrivalAt($events));
            $departure = $this->clock($mark->at);
            $friday = (int) $day->format('w') === 5;
            if ($trips === []) {
                $rows[] = $this->row($day, $arrival, $departure, $mark->isDefault, null, true, $friday);
            } else {
                foreach ($trips as $index => $trip) {
                    $rows[] = $this->row(
                        $day,
                        $arrival,
                        $departure,
                        $mark->isDefault,
                        $trip,
                        $index === 0,
                        $friday,
                    );
                }
            }
            $day = $day->modify('+1 day');
        }

        return $rows;
    }

    private function row(
        DateTimeImmutable $day,
        string $arrival,
        string $departure,
        bool $departureIsDefault,
        ?MovementTripStop $trip,
        bool $leading,
        bool $friday,
    ): DriverMovementRow {
        return new DriverMovementRow(
            dayNumber: $leading ? $day->format('j') : '',
            weekday: $leading ? self::WEEKDAYS[(int) $day->format('w')] : '',
            date: $leading ? $day->format('d-M-y') : '',
            arrival: $leading ? $arrival : '',
            departure: $leading ? $departure : '',
            departureIsDefault: $leading && $departureIsDefault,
            from: $trip === null ? '' : $this->joinNames($trip->fromNames),
            to: $trip === null ? '' : $this->joinNames($trip->toNames),
            started: $this->clock($trip?->startedAt),
            ended: $this->clock($trip?->finishedAt),
            friday: $friday,
            leading: $leading,
        );
    }

    /**
     * @param  list<MovementTripStop>  $trips
     * @return array<string, list<MovementTripStop>>
     */
    private function tripsByDay(array $trips): array
    {
        $grouped = [];
        foreach ($trips as $trip) {
            $key = $this->dayKey($trip->anchor());
            if ($key === null) {
                continue;
            }
            $grouped[$key][] = $trip;
        }

        return $grouped;
    }

    /**
     * @param  list<AvailabilityPresence>  $presence
     * @return array<string, list<AvailabilityPresence>>
     */
    private function presenceByDay(array $presence): array
    {
        $grouped = [];
        foreach ($presence as $event) {
            $key = $this->dayKey($event->requestedAt);
            if ($key === null) {
                continue;
            }
            $grouped[$key][] = $event;
        }

        return $grouped;
    }

    private function dayKey(?DateTimeImmutable $instant): ?string
    {
        if ($instant === null) {
            return null;
        }

        return $instant->setTimezone($this->timezone())->format('Y-m-d');
    }

    private function clock(?DateTimeImmutable $instant): string
    {
        if ($instant === null) {
            return '';
        }

        $local = $instant->setTimezone($this->timezone());
        $hour = (int) $local->format('G') % 12;
        if ($hour === 0) {
            $hour = 12;
        }

        return $hour.'.'.$local->format('i');
    }

    /**
     * @param  list<string>  $names
     */
    private function joinNames(array $names): string
    {
        $unique = [];
        foreach ($names as $name) {
            $trimmed = trim($name);
            if ($trimmed === '' || in_array($trimmed, $unique, true)) {
                continue;
            }
            $unique[] = $trimmed;
        }

        return implode(' · ', $unique);
    }

    private function monthLabel(DateTimeImmutable $day): string
    {
        $local = $day->setTimezone($this->timezone());
        $month = self::MONTHS[(int) $local->format('n')];

        return 'شهر '.$month.' '.$local->format('Y');
    }

    private function timezone(): DateTimeZone
    {
        return $this->periods->timezone();
    }
}
