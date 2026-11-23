<?php

declare(strict_types=1);

namespace App\Http\Requests\Places;

use App\Application\Places\DTOs\UpdatePlaceData;
use App\Models\Place;
use Illuminate\Foundation\Http\FormRequest;

final class UpdatePlaceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Only sent fields are validated. `required` rejects boolean false, so
     * flags use `sometimes` + `boolean`. A full body still validates.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name_en' => ['sometimes', 'required', 'string', 'max:255'],
            'name_ar' => ['sometimes', 'required', 'string', 'max:255'],
            'latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90', 'required_with:longitude'],
            'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180', 'required_with:latitude'],
            'address' => ['sometimes', 'nullable', 'string', 'max:500'],
            'is_headquarters' => ['sometimes', 'boolean'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }

    public function toDto(): UpdatePlaceData
    {
        $place = Place::query()->findOrFail((string) $this->route('id'));

        return new UpdatePlaceData(
            id: (string) $place->id,
            nameEn: $this->exists('name_en') ? (string) $this->validated('name_en') : $place->name_en,
            nameAr: $this->exists('name_ar') ? (string) $this->validated('name_ar') : $place->name_ar,
            latitude: $this->optionalFloat('latitude', $place->latitude),
            longitude: $this->optionalFloat('longitude', $place->longitude),
            address: $this->exists('address') ? $this->validated('address') : $place->address,
            isHeadquarters: $this->exists('is_headquarters') ? $this->boolean('is_headquarters') : (bool) $place->is_headquarters,
            isActive: $this->exists('is_active') ? $this->boolean('is_active') : (bool) $place->is_active,
        );
    }

    private function optionalFloat(string $key, mixed $current): ?float
    {
        if (! $this->exists($key)) {
            return $current === null ? null : (float) $current;
        }

        $value = $this->validated($key);

        return $value === null ? null : (float) $value;
    }
}
