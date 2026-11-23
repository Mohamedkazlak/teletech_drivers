<?php

declare(strict_types=1);

namespace App\Http\Requests\TripRequests;

use App\Application\TripRequests\DTOs\ListTripRequestsData;
use App\Domain\Enums\Branch;
use App\Domain\Enums\TripRequestStage;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;
use App\Http\Requests\Concerns\NormalizesBooleanQuery;
use App\Http\Requests\Concerns\ParsesIso8601;
use App\Http\Requests\Rules\FleetPeriod;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListTripRequestsRequest extends FormRequest
{
    use NormalizesBooleanQuery;
    use ParsesIso8601;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->normalizeBooleanQuery('has_trip');
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'status' => ['sometimes', 'nullable', Rule::enum(TripRequestStatus::class)],
            'has_trip' => ['sometimes', 'nullable', 'boolean'],
            'branch' => ['sometimes', 'nullable', Rule::enum(Branch::class)],
            'stage' => ['sometimes', 'nullable', Rule::enum(TripRequestStage::class)],
            'date_from' => ['sometimes', 'nullable', 'date'],
            'date_to' => ['sometimes', 'nullable', 'date'],
            'employee_id' => ['sometimes', 'nullable', 'uuid'],
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            ...FleetPeriod::rules(),
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): ListTripRequestsData
    {
        /** @var User $user */
        $user = $this->user();
        $status = $this->validated('status');
        $branch = $this->validated('branch');
        $stage = $this->validated('stage');
        $period = $this->validated('period');
        $periodDate = $this->validated('date');

        return new ListTripRequestsData(
            status: $user->role === UserRole::DriversAdmin
                ? TripRequestStatus::Approved
                : (is_string($status) && $status !== '' ? TripRequestStatus::from($status) : null),
            hasTrip: $this->has('has_trip') ? $this->boolean('has_trip') : null,
            dateFrom: $this->parseOptionalDateTime($this->validated('date_from')),
            dateTo: $this->parseOptionalDateTime($this->validated('date_to')),
            employeeId: $this->validated('employee_id'),
            search: $this->validated('search'),
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
            branch: is_string($branch) && $branch !== '' ? Branch::from($branch) : null,
            stage: is_string($stage) && $stage !== '' ? TripRequestStage::from($stage) : null,
            period: is_string($period) && $period !== '' ? $period : null,
            periodDate: is_string($periodDate) && $periodDate !== '' ? $periodDate : null,
        );
    }
}
