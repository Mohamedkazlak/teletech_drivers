<?php

declare(strict_types=1);

namespace App\Models\Concerns;

use App\Domain\Services\FleetPeriodRange;
use DateTimeInterface;
use DateTimeZone;
use Illuminate\Database\Eloquent\Builder;

trait ScopesFleetPeriod
{
    /**
     * Restrict rows to the business-timezone period containing $date (default: today).
     *
     * Bounds are converted to UTC instants and compared with >= and <.
     * The app stores timestamps in UTC, and PostgreSQL columns are
     * "timestamp without time zone", so this stays portable on PostgreSQL and SQLite.
     *
     * @param  Builder<static>  $query
     */
    public function scopeWhereFleetPeriod(
        Builder $query,
        string $column,
        ?string $period,
        DateTimeInterface|string|null $date = null,
    ): Builder {
        // "all" is an unbounded stats period: every timestamp qualifies.
        if ($period === null || $period === '' || $period === 'all') {
            return $query;
        }

        $bounds = FleetPeriodRange::fromConfig()->containing($period, $date);
        $utc = new DateTimeZone('UTC');
        $qualified = str_contains($column, '.')
            ? $column
            : $query->getModel()->qualifyColumn($column);

        return $query
            ->where($qualified, '>=', $bounds['start']->setTimezone($utc))
            ->where($qualified, '<', $bounds['end_exclusive']->setTimezone($utc));
    }
}
