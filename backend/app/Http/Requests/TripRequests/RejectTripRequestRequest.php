<?php

declare(strict_types=1);

namespace App\Http\Requests\TripRequests;

use App\Application\TripRequests\DTOs\RejectTripRequestData;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

final class RejectTripRequestRequest extends FormRequest
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
            'rejection_reason' => ['sometimes', 'nullable', 'string', 'max:500'],
        ];
    }

    public function toDto(): RejectTripRequestData
    {
        /** @var User $user */
        $user = $this->user();
        $reason = $this->validated('rejection_reason');
        $trimmed = is_string($reason) ? trim($reason) : null;

        return new RejectTripRequestData(
            requestId: (string) $this->route('id'),
            handledBy: (string) $user->id,
            rejectionReason: ($trimmed === null || $trimmed === '') ? null : $trimmed,
        );
    }
}
