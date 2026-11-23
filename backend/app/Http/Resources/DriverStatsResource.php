<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\DriverStats;
use App\Domain\Entities\StatsBucket;
use App\Domain\Services\StatsAggregator;
use DateTimeImmutable;
use DateTimeZone;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin DriverStats
 */
final class DriverStatsResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var DriverStats $stats */
        $stats = $this->resource;

        return [
            'period' => $stats->period,
            'from' => $this->instant($stats->from),
            'to' => $this->instant($stats->to),
            'trips' => $stats->trips,
            'total_seconds' => $stats->totalSeconds,
            'total_km' => StatsAggregator::kilometers($stats->totalDistanceM),
            'breakdown' => array_map(
                fn (StatsBucket $bucket): array => [
                    'label' => $bucket->label,
                    'from' => $this->instant($bucket->from),
                    'to' => $this->instant($bucket->to),
                    'trips' => $bucket->trips,
                    'total_seconds' => $bucket->totalSeconds,
                    'total_km' => StatsAggregator::kilometers($bucket->totalDistanceM),
                ],
                $stats->breakdown,
            ),
        ];
    }

    private function instant(?DateTimeImmutable $value): ?string
    {
        return $value?->setTimezone(new DateTimeZone('UTC'))->format(DATE_ATOM);
    }
}
