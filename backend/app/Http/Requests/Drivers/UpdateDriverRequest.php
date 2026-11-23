<?php

declare(strict_types=1);

namespace App\Http\Requests\Drivers;

use App\Application\Drivers\DTOs\UpdateDriverData;
use App\Domain\Drivers\EgyptianCarPlate;
use App\Domain\Enums\UserRole;
use App\Models\User;
use App\Rules\EgyptianCarPlateRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

final class UpdateDriverRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Only sent fields are validated. Boolean false is a real value, so
     * `is_active` is `sometimes|boolean` rather than `required`.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name_en' => ['sometimes', 'required', 'string', 'max:255'],
            'name_ar' => ['sometimes', 'required', 'string', 'max:255'],
            'phone' => ['sometimes', 'required', 'string', 'max:50', 'regex:/^\+?[0-9\s-]{8,20}$/'],
            'national_id' => ['sometimes', 'required', 'string', 'max:100'],
            'car_license' => ['sometimes', 'required', 'string', 'max:100', new EgyptianCarPlateRule],
            'personal_license' => ['sometimes', 'required', 'string', 'max:100'],
            'favorite_place_ids' => ['sometimes', 'array', 'max:5'],
            'favorite_place_ids.*' => [
                'uuid',
                Rule::exists('places', 'id')->where(
                    fn ($query) => $query->where('is_active', true)->whereNull('deleted_at'),
                ),
            ],
            'is_active' => ['sometimes', 'boolean'],
            'password' => ['sometimes', 'nullable', 'string', Password::defaults()],
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

    public function toDto(): UpdateDriverData
    {
        $driver = User::query()
            ->with(['driverProfile', 'favoritePlaces'])
            ->where('role', UserRole::Driver)
            ->findOrFail((string) $this->route('id'));

        /** @var list<string> $favoritePlaceIds */
        $favoritePlaceIds = $this->exists('favorite_place_ids')
            ? array_values($this->validated('favorite_place_ids'))
            : $driver->favoritePlaces
                ->pluck('id')
                ->map(static fn ($id): string => (string) $id)
                ->all();

        $password = $this->validated('password');
        $profile = $driver->driverProfile;

        return new UpdateDriverData(
            id: (string) $driver->id,
            nameEn: $this->exists('name_en') ? (string) $this->validated('name_en') : $driver->name_en,
            nameAr: $this->exists('name_ar') ? (string) $this->validated('name_ar') : $driver->name_ar,
            phone: $this->exists('phone') ? $this->validated('phone') : $driver->phone,
            nationalId: $this->exists('national_id') ? (string) $this->validated('national_id') : (string) ($profile?->national_id ?? ''),
            carLicense: $this->exists('car_license')
                ? (EgyptianCarPlate::canonical((string) $this->validated('car_license')) ?? '')
                : (string) ($profile?->car_license ?? ''),
            personalLicense: $this->exists('personal_license') ? (string) $this->validated('personal_license') : (string) ($profile?->personal_license ?? ''),
            favoritePlaceIds: $favoritePlaceIds,
            isActive: $this->exists('is_active') ? $this->boolean('is_active') : (bool) $driver->is_active,
            password: is_string($password) && $password !== '' ? $password : null,
        );
    }
}
