<?php

declare(strict_types=1);

namespace App\Domain\Services;

use DateTimeImmutable;
use DateTimeInterface;
use DateTimeZone;

/**
 * Africa/Cairo work dates and the configurable weekly off days.
 * 0 = Sunday … 6 = Saturday. Friday is 5.
 */
final class AttendanceClock
{
    public function __construct(
        private readonly DateTimeZone $timezone,
        /** @var list<int> */
        private readonly array $weeklyOffDays,
    ) {}

    public static function fromConfig(): self
    {
        /** @var list<int> $offDays */
        $offDays = array_map('intval', (array) config('attendance.weekly_off_days', [5]));

        return new self(
            new DateTimeZone((string) config('teletech.business_timezone', 'Africa/Cairo')),
            $offDays,
        );
    }

    public function timezone(): DateTimeZone
    {
        return $this->timezone;
    }

    public function now(): DateTimeImmutable
    {
        return DateTimeImmutable::createFromInterface(now())->setTimezone($this->timezone);
    }

    public function today(): string
    {
        return $this->workDate($this->now());
    }

    public function workDate(DateTimeInterface $instant): string
    {
        return DateTimeImmutable::createFromInterface($instant)
            ->setTimezone($this->timezone)
            ->format('Y-m-d');
    }

    public function startOfDay(string $workDate): DateTimeImmutable
    {
        return new DateTimeImmutable($workDate.' 00:00:00', $this->timezone);
    }

    public function isWeeklyOff(string $workDate): bool
    {
        $day = $this->startOfDay($workDate);

        return in_array((int) $day->format('w'), $this->weeklyOffDays, true);
    }

    public function isFuture(string $workDate): bool
    {
        return $workDate > $this->today();
    }
}
