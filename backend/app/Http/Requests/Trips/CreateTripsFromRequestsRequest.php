<?php

declare(strict_types=1);

namespace App\Http\Requests\Trips;

use App\Application\Trips\DTOs\CreateTripsFromRequestsData;
use App\Domain\Enums\TripCreationMode;
use App\Http\Requests\Concerns\ParsesIso8601;
use App\Http\Requests\Concerns\RejectsPastSchedule;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

final class CreateTripsFromRequestsRequest extends FormRequest
{
    use ParsesIso8601;
    use RejectsPastSchedule;

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
            'mode' => ['required', Rule::enum(TripCreationMode::class)],
            'request_ids' => ['required', 'array', 'min:1'],
            'request_ids.*' => ['required', 'uuid', 'distinct'],
            'scheduled_at' => ['nullable', 'date'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $mode = $this->input('mode');
            if ($mode === TripCreationMode::Grouped->value) {
                $ids = $this->input('request_ids');
                if (is_array($ids) && count($ids) < 2) {
                    $validator->errors()->add('request_ids', 'Grouped mode requires at least two requests.');
                }
                if ($this->input('scheduled_at') === null || $this->input('scheduled_at') === '') {
                    $validator->errors()->add('scheduled_at', 'scheduled_at is required for grouped mode.');
                }
            }

            $scheduledAt = $this->input('scheduled_at');
            $this->rejectPastSchedule(
                $validator,
                'scheduled_at',
                is_string($scheduledAt) ? $scheduledAt : null,
            );
        });
    }

    public function toDto(): CreateTripsFromRequestsData
    {
        /** @var User $user */
        $user = $this->user();
        $mode = TripCreationMode::from((string) $this->validated('mode'));

        /** @var list<string> $ids */
        $ids = array_values($this->validated('request_ids'));

        return new CreateTripsFromRequestsData(
            mode: $mode,
            requestIds: $ids,
            scheduledAt: $mode === TripCreationMode::Grouped
                ? $this->parseOptionalDateTime((string) $this->validated('scheduled_at'))
                : null,
            createdBy: (string) $user->id,
        );
    }
}
