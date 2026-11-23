<?php

declare(strict_types=1);

namespace App\Http\Requests\DriverLocations;

use App\Application\DriverLocations\DTOs\PublishDriverLocationData;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

final class PublishDriverLocationRequest extends FormRequest
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
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'heading' => ['required', 'numeric'],
            'speed' => ['required', 'numeric', 'min:0'],
            'accuracy' => ['required', 'numeric', 'min:0'],
            'is_tracking' => ['required', 'boolean'],
            'trip_id' => ['sometimes', 'nullable', 'uuid'],
        ];
    }

    public function toDto(): PublishDriverLocationData
    {
        /** @var User $user */
        $user = $this->user();

        return new PublishDriverLocationData(
            driverId: (string) $user->id,
            lat: (float) $this->validated('lat'),
            lng: (float) $this->validated('lng'),
            heading: (float) $this->validated('heading'),
            speed: (float) $this->validated('speed'),
            accuracy: (float) $this->validated('accuracy'),
            isTracking: (bool) $this->validated('is_tracking'),
            tripId: $this->validated('trip_id'),
        );
    }
}
