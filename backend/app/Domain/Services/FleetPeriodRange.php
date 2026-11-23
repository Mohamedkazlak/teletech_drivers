<?php

declare(strict_types=1);

namespace App\Domain\Services;

use DateTimeImmutable;
use DateTimeInterface;
use DateTimeZone;
use InvalidArgumentException;

/**
 * Inclusive start / exclusive end of a fleet calendar period.
 *
 * Week, month, and year boundaries use the business timezone (Africa/Cairo).
 * The week starts on config('fleet.week_starts_on'), which is Saturday.
 * Driver recommendations and the admin dashboard use this same week.
 */
final class FleetPeriodRange
{
    public function __construct(
        private readonly DateTimeZone $timezone,
        private readonly string $weekStartsOn,
    ) {}

    public function timezone(): DateTimeZone
    {
        return $this->timezone;
    }

    public static function fromConfig(): self
    {
        return new self(
            new DateTimeZone((string) config('teletech.business_timezone', 'Africa/Cairo')),
            (string) config('fleet.week_starts_on', 'Saturday'),
        );
    }

    /**
     * @return array{start: DateTimeImmutable, end_exclusive: DateTimeImmutable}
     */
    public function containing(
        string $period,
        DateTimeInterface|string|null $date = null,
        ?DateTimeImmutable $now = null,
    ): array {
        $day = $this->calendarDay($date, $now);

        return match ($period) {
            'day' => [
                'start' => $day,
                'end_exclusive' => $day->modify('+1 day'),
            ],
            'week' => $this->weekContaining($day),
            'month' => [
                'start' => $day->modify('first day of this month'),
                'end_exclusive' => $day->modify('first day of next month'),
            ],
            'year' => [
                'start' => $day->setDate((int) $day->format('Y'), 1, 1),
                'end_exclusive' => $day->setDate((int) $day->format('Y') + 1, 1, 1),
            ],
            default => throw new InvalidArgumentException('Period must be day, week, month, or year.'),
        };
    }

    /**
     * @return array{start: DateTimeImmutable, end_exclusive: DateTimeImmutable}
     */
    private function weekContaining(DateTimeImmutable $day): array
    {
        $startDow = $this->weekdayIndex($this->weekStartsOn);
        $currentDow = (int) $day->format('w');
        $daysBack = ($currentDow - $startDow + 7) % 7;
        $start = $daysBack === 0 ? $day : $day->modify('-'.$daysBack.' days');

        return [
            'start' => $start,
            'end_exclusive' => $start->modify('+7 days'),
        ];
    }

    private function calendarDay(DateTimeInterface|string|null $date, ?DateTimeImmutable $now): DateTimeImmutable
    {
        return $this->resolveInstant($date, $now)
            ->setTimezone($this->timezone)
            ->setTime(0, 0, 0);
    }

    private function resolveInstant(DateTimeInterface|string|null $date, ?DateTimeImmutable $now): DateTimeImmutable
    {
        if ($date instanceof DateTimeInterface) {
            return DateTimeImmutable::createFromInterface($date);
        }

        if ($date === null || $date === '') {
            return $now ?? DateTimeImmutable::createFromInterface(now());
        }

        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $date) === 1) {
            return new DateTimeImmutable($date.' 00:00:00', $this->timezone);
        }

        if (preg_match('/(?:Z|[+\-]\d{2}:?\d{2})$/', $date) === 1) {
            return new DateTimeImmutable($date);
        }

        return new DateTimeImmutable($date, $this->timezone);
    }

    private function weekdayIndex(string $name): int
    {
        $index = [
            'sunday' => 0,
            'monday' => 1,
            'tuesday' => 2,
            'wednesday' => 3,
            'thursday' => 4,
            'friday' => 5,
            'saturday' => 6,
        ][strtolower(trim($name))] ?? null;

        if ($index === null) {
            throw new InvalidArgumentException('fleet.week_starts_on must be an English weekday name.');
        }

        return $index;
    }

    public function withTimezone(DateTimeZone $timezone): self
    {
        return new self($timezone, $this->weekStartsOn);
    }

    /**
     * True when $instant falls in the period that contains $now.
     * The start is inclusive and the end is exclusive.
     */
    public function includes(
        DateTimeInterface $instant,
        DateTimeImmutable $now,
        string $period = 'week',
    ): bool {
        $bounds = $this->containing($period, null, $now);
        $local = DateTimeImmutable::createFromInterface($instant)->setTimezone($this->timezone);

        return $local >= $bounds['start'] && $local < $bounds['end_exclusive'];
    }
}
