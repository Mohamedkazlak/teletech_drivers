<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Entities\AvailabilityPresence;
use App\Domain\Enums\AvailabilityStatus;
use DateTimeImmutable;

/**
 * Arrival and departure for one Cairo day.
 * Change this class when the clock-in or clock-out rule changes.
 *
 * Arrival is the check-in time. Departure is the check-out time.
 * Events still use the available / finished_today labels so the report
 * can tell them apart. A missing check-out is never written back.
 * A closed day with an arrival or a completed trip and no approved finish
 * prints DEFAULT_DEPARTURE. Today and later stay blank.
 */
final class DriverDayAttendance
{
    /** Business-timezone wall clock. Printed as 5.00. */
    public const DEFAULT_DEPARTURE = '17:00';

    /**
     * @param  list<AvailabilityPresence>  $events
     */
    public function arrivalAt(array $events): ?DateTimeImmutable
    {
        return $this->extreme($events, AvailabilityStatus::Available, latest: false);
    }

    /**
     * @param  list<AvailabilityPresence>  $events
     */
    public function departureAt(array $events): ?DateTimeImmutable
    {
        return $this->extreme($events, AvailabilityStatus::FinishedToday, latest: true);
    }

    /**
     * @param  list<AvailabilityPresence>  $events
     */
    public function departure(
        array $events,
        bool $hasCompletedTrip,
        DateTimeImmutable $day,
        DateTimeImmutable $now,
    ): DayDeparture {
        $explicit = $this->departureAt($events);
        if ($explicit !== null) {
            return new DayDeparture(at: $explicit, isDefault: false);
        }

        $worked = $this->arrivalAt($events) !== null || $hasCompletedTrip;
        if ($worked && $this->dayHasEnded($day, $now)) {
            return new DayDeparture(at: $this->defaultAt($day), isDefault: true);
        }

        return new DayDeparture(at: null, isDefault: false);
    }

    private function dayHasEnded(DateTimeImmutable $day, DateTimeImmutable $now): bool
    {
        $zone = $day->getTimezone();

        return $day->setTimezone($zone)->format('Y-m-d')
            < $now->setTimezone($zone)->format('Y-m-d');
    }

    private function defaultAt(DateTimeImmutable $day): DateTimeImmutable
    {
        if (preg_match('/^(\d{1,2}):(\d{2})$/', self::DEFAULT_DEPARTURE, $match) !== 1) {
            throw new \LogicException('DEFAULT_DEPARTURE must be HH:MM.');
        }

        return $day->setTime((int) $match[1], (int) $match[2], 0);
    }

    /**
     * @param  list<AvailabilityPresence>  $events
     */
    private function extreme(array $events, AvailabilityStatus $status, bool $latest): ?DateTimeImmutable
    {
        $picked = null;
        foreach ($events as $event) {
            if ($event->status !== $status) {
                continue;
            }
            if ($picked === null) {
                $picked = $event->requestedAt;

                continue;
            }
            $isBetter = $latest
                ? $event->requestedAt > $picked
                : $event->requestedAt < $picked;
            if ($isBetter) {
                $picked = $event->requestedAt;
            }
        }

        return $picked;
    }
}
