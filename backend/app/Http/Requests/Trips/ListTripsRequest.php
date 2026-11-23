<?php

declare(strict_types=1);

namespace App\Http\Requests\Trips;

use App\Application\Trips\DTOs\ListTripsData;
use App\Domain\Enums\Branch;
use App\Domain\Enums\CreatedTripListBucket;
use App\Domain\Enums\TripLifecycle;
use App\Domain\Enums\TripStage;
use App\Domain\Enums\TripStatus;
use App\Http\Requests\Concerns\NormalizesBooleanQuery;
use App\Http\Requests\Concerns\ParsesIso8601;
use App\Http\Requests\Rules\TripListPeriod;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListTripsRequest extends FormRequest
{
    use NormalizesBooleanQuery;
    use ParsesIso8601;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->normalizeBooleanQueries('driver_showed_up', 'unconfirmed');
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'status' => ['sometimes', 'nullable', Rule::enum(TripStatus::class)],
            'stage' => ['sometimes', 'nullable', Rule::enum(TripStage::class)],
            'lifecycle' => ['sometimes', 'nullable', Rule::enum(TripLifecycle::class)],
            'branch' => ['sometimes', 'nullable', Rule::enum(Branch::class)],
            'driver_showed_up' => ['sometimes', 'boolean'],
            'driver_id' => ['sometimes', 'nullable', 'uuid'],
            'date_from' => ['sometimes', 'nullable', 'date'],
            'date_to' => ['sometimes', 'nullable', 'date'],
            'period' => ['sometimes', 'nullable', new TripListPeriod],
            'finished_period' => ['sometimes', 'nullable', new TripListPeriod],
            'date' => ['sometimes', 'nullable', 'date'],
            'unconfirmed' => ['sometimes', 'boolean'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ] + ($this->is('api/my-trips') ? [
            'bucket' => ['sometimes', 'nullable', Rule::in([
                'all',
                CreatedTripListBucket::Active->value,
                CreatedTripListBucket::Completed->value,
                CreatedTripListBucket::Cancelled->value,
            ])],
        ] : []);
    }

    public function toDto(): ListTripsData
    {
        $status = $this->validated('status');
        $stage = $this->validated('stage');
        $lifecycle = $this->validated('lifecycle');
        $branch = $this->validated('branch');
        $period = $this->validated('period');
        $finishedPeriod = $this->validated('finished_period');
        $periodDate = $this->validated('date');
        $bucket = $this->validated('bucket');

        return new ListTripsData(
            status: is_string($status) && $status !== '' ? TripStatus::from($status) : null,
            driverId: $this->validated('driver_id'),
            dateFrom: $this->parseOptionalDateTime($this->validated('date_from')),
            dateTo: $this->parseOptionalDateTime($this->validated('date_to')),
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
            stage: is_string($stage) && $stage !== '' ? TripStage::from($stage) : null,
            branch: is_string($branch) && $branch !== '' ? Branch::from($branch) : null,
            driverShowedUp: $this->exists('driver_showed_up') ? $this->boolean('driver_showed_up') : null,
            period: is_string($period) && $period !== '' ? $period : null,
            periodDate: is_string($periodDate) && $periodDate !== '' ? $periodDate : null,
            bucket: is_string($bucket) && $bucket !== '' && $bucket !== 'all'
                ? CreatedTripListBucket::from($bucket)
                : null,
            finishedPeriod: is_string($finishedPeriod) && $finishedPeriod !== '' ? $finishedPeriod : null,
            unconfirmed: $this->exists('unconfirmed') ? $this->boolean('unconfirmed') : null,
            lifecycle: is_string($lifecycle) && $lifecycle !== '' ? TripLifecycle::from($lifecycle) : null,
        );
    }
}
