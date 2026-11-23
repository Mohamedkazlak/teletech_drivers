<?php

declare(strict_types=1);

namespace App\Http\Requests\Trips;

use App\Application\Trips\DTOs\EndTripData;
use App\Http\Requests\Rules\EncodedPolyline;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

final class EndTripRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Empty `return_route` is a zero-point polyline (the driver ended before
     * any return sample was accepted). The empty-string middleware turns ""
     * into null, and `required` would then reject the trip forever.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'return_distance_m' => ['required', 'numeric', 'min:0'],
            'return_route' => ['present', 'nullable', 'string', new EncodedPolyline],
        ];
    }

    public function toDto(): EndTripData
    {
        /** @var User $user */
        $user = $this->user();
        $route = $this->validated('return_route');

        return new EndTripData(
            tripId: (string) $this->route('id'),
            actorId: (string) $user->id,
            returnDistanceM: (int) round((float) $this->validated('return_distance_m')),
            returnRoute: is_string($route) ? $route : '',
        );
    }
}
