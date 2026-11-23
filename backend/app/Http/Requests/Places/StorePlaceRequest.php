<?php

declare(strict_types=1);

namespace App\Http\Requests\Places;

use App\Application\Places\DTOs\CreatePlaceData;
use Illuminate\Foundation\Http\FormRequest;

final class StorePlaceRequest extends FormRequest
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
            'name_en' => ['required', 'string', 'max:255'],
            'name_ar' => ['required', 'string', 'max:255'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90', 'required_with:longitude'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180', 'required_with:latitude'],
            'address' => ['required', 'string', 'max:500'],
            'is_headquarters' => ['sometimes', 'boolean'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }

    public function toDto(): CreatePlaceData
    {
        $latitude = $this->validated('latitude');
        $longitude = $this->validated('longitude');

        return new CreatePlaceData(
            nameEn: (string) $this->validated('name_en'),
            nameAr: (string) $this->validated('name_ar'),
            latitude: $latitude === null ? null : (float) $latitude,
            longitude: $longitude === null ? null : (float) $longitude,
            address: (string) $this->validated('address'),
            isHeadquarters: $this->boolean('is_headquarters'),
            isActive: $this->has('is_active') ? $this->boolean('is_active') : true,
        );
    }
}
