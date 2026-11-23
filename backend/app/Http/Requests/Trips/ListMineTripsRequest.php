<?php

declare(strict_types=1);

namespace App\Http\Requests\Trips;

use App\Application\Trips\DTOs\ListMineTripsData;
use App\Domain\Enums\TripStatus;
use App\Http\Requests\Rules\FleetPeriod;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListMineTripsRequest extends FormRequest
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
            'status' => ['sometimes', 'nullable', Rule::in([
                'all_assigned',
                TripStatus::Unassigned->value,
                TripStatus::Assigned->value,
                TripStatus::Going->value,
                TripStatus::AtDestination->value,
                TripStatus::Returning->value,
                TripStatus::Completed->value,
                TripStatus::Cancelled->value,
            ])],
            ...FleetPeriod::rules(),
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): ListMineTripsData
    {
        /** @var User $user */
        $user = $this->user();
        $status = $this->validated('status');
        $period = $this->validated('period');
        $periodDate = $this->validated('date');
        $statuses = null;
        $single = null;

        if ($status === 'all_assigned') {
            $statuses = [
                TripStatus::Assigned,
                TripStatus::Going,
                TripStatus::AtDestination,
                TripStatus::Returning,
            ];
        } elseif (is_string($status) && $status !== '') {
            $single = TripStatus::from($status);
        }

        return new ListMineTripsData(
            driverId: (string) $user->id,
            status: $single,
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
            statuses: $statuses,
            period: is_string($period) && $period !== '' ? $period : null,
            periodDate: is_string($periodDate) && $periodDate !== '' ? $periodDate : null,
        );
    }
}
