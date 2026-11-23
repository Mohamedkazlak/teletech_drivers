<?php

declare(strict_types=1);

namespace App\Domain\Services;

use DateTimeImmutable;
use DateTimeZone;

/**
 * "Now" for scheduling is the current instant in the business timezone
 * (Africa/Cairo). Comparisons use that instant, so an offset on the
 * submitted time is honored.
 */
final class ScheduleTime
{
    public function __construct(private readonly DateTimeZone $timezone) {}

    public static function fromConfig(): self
    {
        return new self(new DateTimeZone((string) config('teletech.business_timezone', 'Africa/Cairo')));
    }

    public function now(): DateTimeImmutable
    {
        return DateTimeImmutable::createFromInterface(now($this->timezone));
    }

    public function isNotFuture(DateTimeImmutable $moment): bool
    {
        return $moment->getTimestamp() <= $this->now()->getTimestamp();
    }
}
