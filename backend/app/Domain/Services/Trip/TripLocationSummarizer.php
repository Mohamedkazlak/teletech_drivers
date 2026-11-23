<?php

declare(strict_types=1);

namespace App\Domain\Services\Trip;

/**
 * Builds pickup/destination summary strings for trips (mirrors Flutter GroupedRequests).
 */
final class TripLocationSummarizer
{
    /**
     * @param  list<string>  $values
     */
    public function summarize(array $values): string
    {
        $ordered = [];
        $seen = [];
        foreach ($values as $value) {
            if (! isset($seen[$value])) {
                $seen[$value] = true;
                $ordered[] = $value;
            }
        }

        return implode(' · ', $ordered);
    }
}
