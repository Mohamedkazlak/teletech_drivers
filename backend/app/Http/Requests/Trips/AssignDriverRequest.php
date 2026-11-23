<?php

declare(strict_types=1);

namespace App\Http\Requests\Trips;

use App\Application\Trips\DTOs\AssignDriverData;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

final class AssignDriverRequest extends FormRequest
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
            'driver_id' => ['required', 'uuid'],
        ];
    }

    public function toDto(): AssignDriverData
    {
        /** @var User $user */
        $user = $this->user();

        return new AssignDriverData(
            tripId: (string) $this->route('id'),
            driverId: (string) $this->validated('driver_id'),
            actorId: (string) $user->id,
        );
    }
}
