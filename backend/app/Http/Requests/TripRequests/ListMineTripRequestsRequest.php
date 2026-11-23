<?php

declare(strict_types=1);

namespace App\Http\Requests\TripRequests;

use App\Application\TripRequests\DTOs\ListMineTripRequestsData;
use App\Domain\Enums\TripRequestListBucket;
use App\Domain\Enums\TripRequestStatus;
use App\Http\Requests\Concerns\NormalizesBooleanQuery;
use App\Http\Requests\Concerns\ParsesIso8601;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListMineTripRequestsRequest extends FormRequest
{
    use NormalizesBooleanQuery;
    use ParsesIso8601;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->normalizeBooleanQueries('awaiting_confirmation');
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'status' => ['sometimes', 'nullable', Rule::enum(TripRequestStatus::class)],
            'bucket' => ['sometimes', 'nullable', Rule::enum(TripRequestListBucket::class)],
            'awaiting_confirmation' => ['sometimes', 'boolean'],
            'date_from' => ['sometimes', 'nullable', 'date'],
            'date_to' => ['sometimes', 'nullable', 'date'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): ListMineTripRequestsData
    {
        /** @var User $user */
        $user = $this->user();
        $status = $this->validated('status');
        $bucket = $this->validated('bucket');

        return new ListMineTripRequestsData(
            employeeId: (string) $user->id,
            status: is_string($status) && $status !== '' ? TripRequestStatus::from($status) : null,
            dateFrom: $this->parseOptionalDateTime($this->validated('date_from')),
            dateTo: $this->parseOptionalDateTime($this->validated('date_to')),
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
            bucket: is_string($bucket) && $bucket !== '' ? TripRequestListBucket::from($bucket) : null,
            awaitingConfirmation: $this->boolean('awaiting_confirmation'),
        );
    }
}
