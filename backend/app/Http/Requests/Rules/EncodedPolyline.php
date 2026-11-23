<?php

declare(strict_types=1);

namespace App\Http\Requests\Rules;

use App\Domain\Services\PolylineValidator;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

final class EncodedPolyline implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_string($value)) {
            $fail('The :attribute must be an encoded polyline string.');

            return;
        }

        $validator = PolylineValidator::fromConfig();
        if (! $validator->isValid($value)) {
            $fail('The :attribute must be a valid encoded polyline within the configured max length.');
        }
    }
}
