<?php

declare(strict_types=1);

namespace App\Http\Requests\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

/**
 * Reusable period + date rules. Apply the matching query with whereFleetPeriod().
 */
final class FleetPeriod implements ValidationRule
{
    public function __construct(
        private readonly bool $allowAll = false,
    ) {}

    /**
     * @return array<string, list<mixed>>
     */
    public static function rules(bool $required = false, bool $allowAll = false): array
    {
        return [
            'period' => [$required ? 'required' : 'sometimes', 'nullable', new self($allowAll)],
            'date' => ['sometimes', 'nullable', 'date'],
        ];
    }

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if ($value === null || $value === '') {
            return;
        }

        $allowed = $this->allowAll
            ? ['week', 'month', 'year', 'all']
            : ['week', 'month', 'year'];

        if (! is_string($value) || ! in_array($value, $allowed, true)) {
            $fail($this->allowAll
                ? 'The :attribute must be week, month, year, or all.'
                : 'The :attribute must be week, month, or year.');
        }
    }
}
