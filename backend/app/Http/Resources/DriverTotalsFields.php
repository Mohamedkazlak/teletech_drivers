<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\DriverStats;
use App\Domain\Services\StatsAggregator;

final class DriverTotalsFields
{
    /**
     * @return array<string, mixed>
     */
    public static function payload(?DriverStats $totals): array
    {
        if ($totals === null) {
            return [];
        }

        return [
            'totals' => [
                'trips' => $totals->trips,
                'total_seconds' => $totals->totalSeconds,
                'total_km' => StatsAggregator::kilometers($totals->totalDistanceM),
            ],
        ];
    }
}
