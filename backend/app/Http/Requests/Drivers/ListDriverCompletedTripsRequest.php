<?php

declare(strict_types=1);

namespace App\Http\Requests\Drivers;

use App\Application\Drivers\DTOs\ListDriverCompletedTripsData;
use App\Http\Requests\Rules\FleetPeriod;
use Illuminate\Foundation\Http\FormRequest;

final class ListDriverCompletedTripsRequest extends FormRequest
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
        return [
            ...FleetPeriod::rules(allowAll: true),
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): ListDriverCompletedTripsData
    {
        $period = $this->validated('period');
        $date = $this->validated('date');

        return new ListDriverCompletedTripsData(
            driverId: (string) $this->route('id'),
            period: is_string($period) && $period !== '' ? $period : null,
            date: is_string($date) && $date !== '' ? $date : null,
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
        );
    }
}
