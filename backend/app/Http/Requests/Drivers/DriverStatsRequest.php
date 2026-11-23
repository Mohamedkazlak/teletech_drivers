<?php

declare(strict_types=1);

namespace App\Http\Requests\Drivers;

use App\Http\Requests\Rules\FleetPeriod;
use Illuminate\Foundation\Http\FormRequest;

final class DriverStatsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return FleetPeriod::rules(required: true, allowAll: true);
    }

    public function period(): string
    {
        return (string) $this->validated('period');
    }

    public function anchorDate(): ?string
    {
        $date = $this->validated('date');

        return is_string($date) && $date !== '' ? $date : null;
    }
}
