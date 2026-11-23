<?php

declare(strict_types=1);

namespace App\Http\Requests\Trips;

use App\Application\Trips\DTOs\StartTripData;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

final class StartTripRequest extends FormRequest
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
            'start_lat' => ['required', 'numeric', 'between:-90,90'],
            'start_lng' => ['required', 'numeric', 'between:-180,180'],
        ];
    }

    public function toDto(): StartTripData
    {
        /** @var User $user */
        $user = $this->user();

        return new StartTripData(
            tripId: (string) $this->route('id'),
            actorId: (string) $user->id,
            startLat: (float) $this->validated('start_lat'),
            startLng: (float) $this->validated('start_lng'),
        );
    }
}
