<?php

declare(strict_types=1);

namespace App\Http\Requests\TripRequests;

use App\Application\TripRequests\DTOs\ApproveGroupTripRequestsData;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

final class ApproveGroupTripRequestsRequest extends FormRequest
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
            'request_ids' => ['required', 'array', 'min:2'],
            'request_ids.*' => ['required', 'uuid', 'distinct'],
        ];
    }

    public function toDto(): ApproveGroupTripRequestsData
    {
        /** @var User $user */
        $user = $this->user();

        /** @var list<string> $ids */
        $ids = array_values($this->validated('request_ids'));

        return new ApproveGroupTripRequestsData(
            requestIds: $ids,
            handledBy: (string) $user->id,
        );
    }
}
