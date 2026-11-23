<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Entities\TrackingPoint;

/**
 * Keeps a driven route within a fixed point cap, including both ends.
 */
final class TrackingRouteSampler
{
    public const MAX_POINTS = 500;

    /**
     * @param  list<TrackingPoint>  $points
     * @return list<TrackingPoint>
     */
    public function cap(array $points, int $max = self::MAX_POINTS): array
    {
        $points = array_values($points);
        $count = count($points);
        if ($max < 1 || $count === 0) {
            return [];
        }

        if ($count <= $max) {
            return $points;
        }

        if ($max === 1) {
            return [$points[0]];
        }

        $last = $count - 1;
        $sampled = [];
        $seen = [];
        for ($i = 0; $i < $max; $i++) {
            $index = (int) round($i * $last / ($max - 1));
            if (isset($seen[$index])) {
                continue;
            }

            $seen[$index] = true;
            $sampled[] = $points[$index];
        }

        return $sampled;
    }
}
