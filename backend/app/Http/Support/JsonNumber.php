<?php

declare(strict_types=1);

namespace App\Http\Support;

/**
 * JSON numbers for coordinates. Postgres decimals arrive as strings.
 */
final class JsonNumber
{
    public static function orNull(mixed $value): ?float
    {
        if ($value === null || $value === '') {
            return null;
        }

        if (is_int($value) || is_float($value)) {
            return (float) $value;
        }

        if (is_string($value) && is_numeric($value)) {
            return (float) $value;
        }

        return null;
    }
}
