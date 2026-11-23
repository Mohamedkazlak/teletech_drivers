<?php

declare(strict_types=1);

namespace App\Http\Requests\Drivers;

use App\Application\Drivers\DTOs\CreateDriverData;
use App\Domain\Drivers\EgyptianCarPlate;
use App\Rules\EgyptianCarPlateRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

final class StoreDriverRequest extends FormRequest
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
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', Password::defaults()],
            'phone' => ['required', 'string', 'max:50', 'regex:/^\+?[0-9\s-]{8,20}$/'],
            'national_id' => ['required', 'string', 'max:100'],
            'car_license' => ['required', 'string', 'max:100', new EgyptianCarPlateRule],
            'personal_license' => ['required', 'string', 'max:100'],
            'favorite_place_ids' => ['present', 'array', 'max:5'],
            'favorite_place_ids.*' => [
                'uuid',
                Rule::exists('places', 'id')->where(
                    fn ($query) => $query->where('is_active', true)->whereNull('deleted_at'),
                ),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'phone.regex' => __('messages.phone_invalid'),
        ];
    }

    public function toDto(): CreateDriverData
    {
        /** @var list<string> $favoritePlaceIds */
        $favoritePlaceIds = array_values($this->validated('favorite_place_ids'));

        return new CreateDriverData(
            nameEn: (string) $this->validated('name_en'),
            nameAr: (string) $this->validated('name_ar'),
            email: (string) $this->validated('email'),
            password: (string) $this->validated('password'),
            phone: (string) $this->validated('phone'),
            nationalId: (string) $this->validated('national_id'),
            carLicense: EgyptianCarPlate::canonical((string) $this->validated('car_license')) ?? '',
            personalLicense: (string) $this->validated('personal_license'),
            favoritePlaceIds: $favoritePlaceIds,
        );
    }
}
