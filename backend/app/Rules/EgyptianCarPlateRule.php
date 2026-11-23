<?php

declare(strict_types=1);

namespace App\Rules;

use App\Domain\Drivers\EgyptianCarPlate;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

final class EgyptianCarPlateRule implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_string($value) || EgyptianCarPlate::canonical($value) === null) {
            $fail(__('messages.egyptian_car_plate'));
        }
    }
}
