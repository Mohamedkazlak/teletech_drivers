<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Enums\HqDistanceBand;

/**
 * Maps distance-from-HQ meters to near / medium / far / unknown bands.
 */
final class HqDistanceClassifier
{
    public function __construct(
        private readonly int $nearMeters,
        private readonly int $mediumMeters,
    ) {}

    public static function fromConfig(): self
    {
        return new self(
            nearMeters: (int) config('teletech.hq_near_meters', 200),
            mediumMeters: (int) config('teletech.hq_medium_meters', 1000),
        );
    }

    public function classify(?float $distanceMeters): HqDistanceBand
    {
        if ($distanceMeters === null || ! is_finite($distanceMeters) || $distanceMeters < 0) {
            return HqDistanceBand::Unknown;
        }

        if ($distanceMeters <= $this->nearMeters) {
            return HqDistanceBand::Near;
        }

        if ($distanceMeters <= $this->mediumMeters) {
            return HqDistanceBand::Medium;
        }

        return HqDistanceBand::Far;
    }
}
