<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Entities\CountableTrip;
use App\Domain\Entities\DriverStats;
use App\Domain\Entities\StatsBucket;
use DateTimeImmutable;
use InvalidArgumentException;

/**
 * Shared trip totals for a driver's own stats, an admin's driver stats,
 * and the all-time totals on a driver profile.
 *
 * Callers pass trips already limited to status=completed, a non-null
 * finished_at, and driver_showed_up IS NOT FALSE. This class places those
 * trips into Africa/Cairo buckets (week starts Saturday) and skips a trip
 * in the time total when either timestamp is missing. Null distance is 0.
 * Buckets are built in PHP so SQLite tests and PostgreSQL agree.
 */
final class StatsAggregator
{
    public function __construct(
        private readonly FleetPeriodRange $periods,
    ) {}

    public static function kilometers(?int $meters): float
    {
        return round(($meters ?? 0) / 1000, 2);
    }

    /**
     * Seconds between the two timestamps. Null when either is missing,
     * so the trip still counts but does not change the time total.
     */
    public static function durationSeconds(
        ?DateTimeImmutable $started,
        ?DateTimeImmutable $finished,
    ): ?int {
        if ($started === null || $finished === null) {
            return null;
        }

        return $finished->getTimestamp() - $started->getTimestamp();
    }

    /**
     * @param  list<CountableTrip>  $trips
     */
    public function aggregate(string $period, ?string $date, array $trips): DriverStats
    {
        if ($period === 'all') {
            return $this->aggregateAll($trips);
        }

        if (! in_array($period, ['week', 'month', 'year'], true)) {
            throw new InvalidArgumentException('Period must be week, month, year, or all.');
        }

        $bounds = $this->periods->containing($period, $date);
        $included = array_values(array_filter(
            $trips,
            static fn (CountableTrip $trip): bool => $trip->finishedAt >= $bounds['start']
                && $trip->finishedAt < $bounds['end_exclusive'],
        ));

        $buckets = $period === 'year'
            ? $this->monthBuckets($bounds['start'], $bounds['end_exclusive'])
            : $this->dayBuckets($bounds['start'], $bounds['end_exclusive']);

        $totals = $this->sum($included);

        return new DriverStats(
            period: $period,
            from: $bounds['start'],
            to: $bounds['end_exclusive'],
            trips: $totals['trips'],
            totalSeconds: $totals['seconds'],
            totalDistanceM: $totals['meters'],
            breakdown: $this->fill($buckets, $included),
        );
    }

    /**
     * @param  list<CountableTrip>  $trips
     */
    private function aggregateAll(array $trips): DriverStats
    {
        $timezone = $this->periods->timezone();
        $years = [];
        foreach ($trips as $trip) {
            $years[(int) $trip->finishedAt->setTimezone($timezone)->format('Y')] = true;
        }
        ksort($years);

        $buckets = [];
        foreach (array_keys($years) as $year) {
            $from = new DateTimeImmutable(sprintf('%04d-01-01 00:00:00', $year), $timezone);
            $buckets[] = [
                'label' => (string) $year,
                'from' => $from,
                'to' => $from->modify('+1 year'),
            ];
        }

        $totals = $this->sum($trips);

        return new DriverStats(
            period: 'all',
            from: $buckets[0]['from'] ?? null,
            to: $buckets === [] ? null : $buckets[array_key_last($buckets)]['to'],
            trips: $totals['trips'],
            totalSeconds: $totals['seconds'],
            totalDistanceM: $totals['meters'],
            breakdown: $this->fill($buckets, $trips),
        );
    }

    /**
     * @return list<array{label: string, from: DateTimeImmutable, to: DateTimeImmutable}>
     */
    private function dayBuckets(DateTimeImmutable $start, DateTimeImmutable $end): array
    {
        $buckets = [];
        $cursor = $start;
        while ($cursor < $end) {
            $next = $cursor->modify('+1 day');
            $buckets[] = [
                'label' => $cursor->format('Y-m-d'),
                'from' => $cursor,
                'to' => $next,
            ];
            $cursor = $next;
        }

        return $buckets;
    }

    /**
     * @return list<array{label: string, from: DateTimeImmutable, to: DateTimeImmutable}>
     */
    private function monthBuckets(DateTimeImmutable $start, DateTimeImmutable $end): array
    {
        $buckets = [];
        $cursor = $start;
        while ($cursor < $end) {
            $next = $cursor->modify('+1 month');
            $buckets[] = [
                'label' => $cursor->format('Y-m'),
                'from' => $cursor,
                'to' => $next,
            ];
            $cursor = $next;
        }

        return $buckets;
    }

    /**
     * @param  list<array{label: string, from: DateTimeImmutable, to: DateTimeImmutable}>  $buckets
     * @param  list<CountableTrip>  $trips
     * @return list<StatsBucket>
     */
    private function fill(array $buckets, array $trips): array
    {
        $counts = array_fill(0, count($buckets), ['trips' => 0, 'seconds' => 0, 'meters' => 0]);

        foreach ($trips as $trip) {
            foreach ($buckets as $index => $bucket) {
                if ($trip->finishedAt < $bucket['from'] || $trip->finishedAt >= $bucket['to']) {
                    continue;
                }

                $counts[$index]['trips']++;
                $duration = self::durationSeconds($trip->goingStartedAt, $trip->finishedAt);
                if ($duration !== null) {
                    $counts[$index]['seconds'] += $duration;
                }
                $counts[$index]['meters'] += $trip->totalDistanceM ?? 0;
                break;
            }
        }

        $result = [];
        foreach ($buckets as $index => $bucket) {
            $result[] = new StatsBucket(
                label: $bucket['label'],
                from: $bucket['from'],
                to: $bucket['to'],
                trips: $counts[$index]['trips'],
                totalSeconds: $counts[$index]['seconds'],
                totalDistanceM: $counts[$index]['meters'],
            );
        }

        return $result;
    }

    /**
     * @param  list<CountableTrip>  $trips
     * @return array{trips: int, seconds: int, meters: int}
     */
    private function sum(array $trips): array
    {
        $seconds = 0;
        $meters = 0;
        foreach ($trips as $trip) {
            $duration = self::durationSeconds($trip->goingStartedAt, $trip->finishedAt);
            if ($duration !== null) {
                $seconds += $duration;
            }
            $meters += $trip->totalDistanceM ?? 0;
        }

        return [
            'trips' => count($trips),
            'seconds' => $seconds,
            'meters' => $meters,
        ];
    }
}
