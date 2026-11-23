<?php

declare(strict_types=1);

namespace App\Http\Requests\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

/**
 * GET /trips period. day, week, and month use the fleet calendar.
 * custom leaves the window to date_from / date_to.
 */
final class TripListPeriod implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if ($value === null || $value === '') {
            return;
        }

        if (! is_string($value) || ! in_array($value, ['day', 'week', 'month', 'custom'], true)) {
            $fail('The :attribute must be day, week, month, or custom.');
        }
    }
}
