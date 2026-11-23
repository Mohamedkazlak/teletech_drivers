<?php

declare(strict_types=1);

namespace App\Http\Requests\Trips;

use App\Application\Trips\DTOs\ArriveAtDestinationData;
use App\Http\Requests\Rules\EncodedPolyline;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

final class ArriveAtDestinationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Empty `going_route` is a zero-point polyline. The empty-string middleware
     * turns "" into null, and `required` would then reject Arrive forever.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'going_distance_m' => ['required', 'numeric', 'min:0'],
            'going_route' => ['present', 'nullable', 'string', new EncodedPolyline],
        ];
    }

    public function toDto(): ArriveAtDestinationData
    {
        /** @var User $user */
        $user = $this->user();
        $route = $this->validated('going_route');

        return new ArriveAtDestinationData(
            tripId: (string) $this->route('id'),
            actorId: (string) $user->id,
            goingDistanceM: (int) round((float) $this->validated('going_distance_m')),
            goingRoute: is_string($route) ? $route : '',
        );
    }
}
