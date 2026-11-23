<?php

declare(strict_types=1);

namespace App\Http\Requests\Trips;

use App\Application\Trips\DTOs\ListCreatedByMeTripsData;
use App\Domain\Enums\CreatedTripListBucket;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListCreatedByMeTripsRequest extends FormRequest
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
            'bucket' => ['sometimes', 'nullable', Rule::enum(CreatedTripListBucket::class)],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): ListCreatedByMeTripsData
    {
        /** @var User $user */
        $user = $this->user();
        $bucket = $this->validated('bucket');

        return new ListCreatedByMeTripsData(
            createdBy: (string) $user->id,
            bucket: is_string($bucket) && $bucket !== ''
                ? CreatedTripListBucket::from($bucket)
                : null,
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
        );
    }
}
