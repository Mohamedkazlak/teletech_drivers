<?php

declare(strict_types=1);

namespace App\Http\Requests\TripRequests;

use App\Application\TripRequests\DTOs\CreateTripRequestData;
use App\Application\TripRequests\DTOs\PlaceInputData;
use App\Domain\Enums\UserRole;
use App\Http\Requests\Concerns\ParsesIso8601;
use App\Http\Requests\Concerns\RejectsPastSchedule;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

final class StoreTripRequestRequest extends FormRequest
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
            'pickup' => ['required', 'array'],
            'pickup.place_id' => ['nullable', 'uuid', 'required_without:pickup.name'],
            'pickup.name' => ['nullable', 'string', 'max:255', 'required_without:pickup.place_id'],
            'pickup.lat' => ['nullable', 'numeric', 'between:-90,90', 'required_with:pickup.name'],
            'pickup.lng' => ['nullable', 'numeric', 'between:-180,180', 'required_with:pickup.name'],
            'pickup.address' => ['nullable', 'string', 'max:500'],
            'destination' => ['required', 'array'],
            'destination.place_id' => ['nullable', 'uuid', 'required_without:destination.name'],
            'destination.name' => ['nullable', 'string', 'max:255', 'required_without:destination.place_id'],
            'destination.lat' => ['nullable', 'numeric', 'between:-90,90', 'required_with:destination.name'],
            'destination.lng' => ['nullable', 'numeric', 'between:-180,180', 'required_with:destination.name'],
            'destination.address' => ['nullable', 'string', 'max:500'],
            'requested_at' => ['required', 'date'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:1000'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $pickupPlaceId = $this->input('pickup.place_id');
            $destinationPlaceId = $this->input('destination.place_id');
            if (is_string($pickupPlaceId) && $pickupPlaceId !== '' && $pickupPlaceId === $destinationPlaceId) {
                $validator->errors()->add('destination', 'Pickup and destination must be different.');
            }

            $requestedAt = $this->input('requested_at');
            $raw = is_string($requestedAt) ? $requestedAt : null;
            $this->rejectPastSchedule($validator, 'requested_at', $raw);
            $this->rejectPastSchedule($validator, 'scheduled_at', $raw);
        });
    }

    public function toDto(): CreateTripRequestData
    {
        /** @var User $user */
        $user = $this->user();

        return new CreateTripRequestData(
            actorId: (string) $user->id,
            actorRole: $user->role instanceof UserRole ? $user->role : UserRole::from((string) $user->role),
            pickup: $this->toPlaceInput('pickup'),
            destination: $this->toPlaceInput('destination'),
            requestedAt: $this->parseOptionalDateTime((string) $this->validated('requested_at'))
                ?? new \DateTimeImmutable((string) $this->validated('requested_at')),
            notes: trim((string) ($this->validated('notes') ?? '')),
        );
    }

    private function toPlaceInput(string $key): PlaceInputData
    {
        $placeId = $this->validated($key.'.place_id');
        $lat = $this->validated($key.'.lat');
        $lng = $this->validated($key.'.lng');

        return new PlaceInputData(
            placeId: is_string($placeId) && $placeId !== '' ? $placeId : null,
            name: isset($this->validated()[$key]['name']) ? trim((string) $this->validated($key.'.name')) : null,
            lat: $lat === null ? null : (float) $lat,
            lng: $lng === null ? null : (float) $lng,
            address: $this->validated($key.'.address'),
        );
    }
}
