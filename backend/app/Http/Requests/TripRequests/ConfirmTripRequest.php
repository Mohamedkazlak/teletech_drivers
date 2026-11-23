<?php

declare(strict_types=1);

namespace App\Http\Requests\TripRequests;

use App\Application\TripRequests\DTOs\ConfirmTripData;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

final class ConfirmTripRequest extends FormRequest
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
            'driver_showed_up' => ['required', 'boolean'],
            'note' => ['sometimes', 'nullable', 'string', 'max:500'],
        ];
    }

    public function toDto(): ConfirmTripData
    {
        /** @var User $user */
        $user = $this->user();
        $note = $this->validated('note');

        return new ConfirmTripData(
            requestId: (string) $this->route('id'),
            actorId: (string) $user->id,
            driverShowedUp: $this->boolean('driver_showed_up'),
            note: is_string($note) && $note !== '' ? $note : null,
        );
    }
}
